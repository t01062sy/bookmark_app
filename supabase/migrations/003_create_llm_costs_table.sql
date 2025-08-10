-- Create llm_costs table for tracking OpenAI API usage and costs
-- Phase 2A Week 3: Cost monitoring system

-- Create enum for LLM models
CREATE TYPE llm_model_type AS ENUM (
  'gpt-4o-mini',
  'gpt-4o',
  'gpt-3.5-turbo',
  'text-embedding-3-small',
  'text-embedding-3-large'
);

-- Create table for tracking LLM costs
CREATE TABLE IF NOT EXISTS llm_costs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  bookmark_id UUID REFERENCES bookmarks(id) ON DELETE CASCADE,
  model llm_model_type NOT NULL,
  prompt_tokens INTEGER NOT NULL DEFAULT 0,
  completion_tokens INTEGER NOT NULL DEFAULT 0,
  total_tokens INTEGER NOT NULL DEFAULT 0,
  cost_usd DECIMAL(10, 6) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  request_type TEXT NOT NULL DEFAULT 'summarization', -- summarization, embedding, etc.
  success BOOLEAN NOT NULL DEFAULT true,
  error_message TEXT
);

-- Create indexes for efficient querying
CREATE INDEX idx_llm_costs_created_at ON llm_costs(created_at DESC);
CREATE INDEX idx_llm_costs_bookmark_id ON llm_costs(bookmark_id);
CREATE INDEX idx_llm_costs_model ON llm_costs(model);
CREATE INDEX idx_llm_costs_daily ON llm_costs(DATE(created_at));

-- Create view for daily cost aggregation
CREATE OR REPLACE VIEW daily_llm_costs AS
SELECT 
  DATE(created_at) as date,
  model,
  COUNT(*) as request_count,
  SUM(prompt_tokens) as total_prompt_tokens,
  SUM(completion_tokens) as total_completion_tokens,
  SUM(total_tokens) as total_tokens,
  SUM(cost_usd) as total_cost_usd,
  COUNT(CASE WHEN success = true THEN 1 END) as successful_requests,
  COUNT(CASE WHEN success = false THEN 1 END) as failed_requests
FROM llm_costs
GROUP BY DATE(created_at), model
ORDER BY date DESC, model;

-- Create view for monthly cost aggregation
CREATE OR REPLACE VIEW monthly_llm_costs AS
SELECT 
  DATE_TRUNC('month', created_at) as month,
  model,
  COUNT(*) as request_count,
  SUM(prompt_tokens) as total_prompt_tokens,
  SUM(completion_tokens) as total_completion_tokens,
  SUM(total_tokens) as total_tokens,
  SUM(cost_usd) as total_cost_usd,
  COUNT(CASE WHEN success = true THEN 1 END) as successful_requests,
  COUNT(CASE WHEN success = false THEN 1 END) as failed_requests
FROM llm_costs
GROUP BY DATE_TRUNC('month', created_at), model
ORDER BY month DESC, model;

-- Create function to calculate cost based on model and tokens
CREATE OR REPLACE FUNCTION calculate_llm_cost(
  p_model llm_model_type,
  p_prompt_tokens INTEGER,
  p_completion_tokens INTEGER
) RETURNS DECIMAL(10, 6) AS $$
DECLARE
  v_cost DECIMAL(10, 6);
BEGIN
  -- Pricing as of 2025-08 (per 1M tokens)
  -- GPT-4o-mini: $0.15 input, $0.60 output per 1M tokens
  -- GPT-4o: $2.50 input, $10.00 output per 1M tokens
  CASE p_model
    WHEN 'gpt-4o-mini' THEN
      v_cost := (p_prompt_tokens * 0.00000015) + (p_completion_tokens * 0.00000060);
    WHEN 'gpt-4o' THEN
      v_cost := (p_prompt_tokens * 0.00000250) + (p_completion_tokens * 0.00001000);
    WHEN 'gpt-3.5-turbo' THEN
      v_cost := (p_prompt_tokens * 0.00000050) + (p_completion_tokens * 0.00000150);
    WHEN 'text-embedding-3-small' THEN
      v_cost := p_prompt_tokens * 0.00000002;
    WHEN 'text-embedding-3-large' THEN
      v_cost := p_prompt_tokens * 0.00000013;
    ELSE
      v_cost := 0.00;
  END CASE;
  
  RETURN v_cost;
END;
$$ LANGUAGE plpgsql;

-- Create function to check daily cost limit
CREATE OR REPLACE FUNCTION check_daily_cost_limit() RETURNS BOOLEAN AS $$
DECLARE
  v_daily_cost DECIMAL(10, 6);
  v_daily_limit DECIMAL(10, 6) := 1.00; -- $1 per day limit
BEGIN
  SELECT COALESCE(SUM(cost_usd), 0) INTO v_daily_cost
  FROM llm_costs
  WHERE DATE(created_at) = CURRENT_DATE;
  
  RETURN v_daily_cost < v_daily_limit;
END;
$$ LANGUAGE plpgsql;

-- Create function to check monthly cost limit
CREATE OR REPLACE FUNCTION check_monthly_cost_limit() RETURNS BOOLEAN AS $$
DECLARE
  v_monthly_cost DECIMAL(10, 6);
  v_monthly_limit DECIMAL(10, 6) := 30.00; -- $30 per month limit
BEGIN
  SELECT COALESCE(SUM(cost_usd), 0) INTO v_monthly_cost
  FROM llm_costs
  WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE);
  
  RETURN v_monthly_cost < v_monthly_limit;
END;
$$ LANGUAGE plpgsql;

-- Add RLS policies
ALTER TABLE llm_costs ENABLE ROW LEVEL SECURITY;

-- Policy for reading costs (anyone can read aggregate data)
CREATE POLICY "Public can read cost aggregates" ON llm_costs
  FOR SELECT
  USING (true);

-- Policy for inserting costs (only service role)
CREATE POLICY "Service role can insert costs" ON llm_costs
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Grant permissions
GRANT SELECT ON llm_costs TO anon, authenticated;
GRANT INSERT, UPDATE ON llm_costs TO authenticated;
GRANT ALL ON llm_costs TO service_role;
GRANT SELECT ON daily_llm_costs TO anon, authenticated;
GRANT SELECT ON monthly_llm_costs TO anon, authenticated;