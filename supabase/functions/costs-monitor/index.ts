// GET /v1/costs - コスト監視API
// Phase 2A Week 3: コスト監視システム実装

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface CostSummary {
  daily: {
    date: string
    total_cost_usd: number
    request_count: number
    limit_usd: number
    remaining_usd: number
    percentage_used: number
  }
  monthly: {
    month: string
    total_cost_usd: number
    request_count: number
    limit_usd: number
    remaining_usd: number
    percentage_used: number
  }
  breakdown_by_model: Array<{
    model: string
    request_count: number
    total_tokens: number
    total_cost_usd: number
  }>
  recent_requests: Array<{
    id: string
    bookmark_id: string
    model: string
    tokens: number
    cost_usd: number
    created_at: string
    success: boolean
  }>
  limits: {
    daily_limit_usd: number
    monthly_limit_usd: number
    is_daily_limit_reached: boolean
    is_monthly_limit_reached: boolean
    can_process_new_request: boolean
  }
}

interface ErrorResponse {
  error: string
  code: string
  details?: any
}

serve(async (req) => {
  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
  }

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Only allow GET
  if (req.method !== 'GET') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed', code: 'METHOD_NOT_ALLOWED' }), 
      { 
        status: 405, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }

  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    const today = new Date().toISOString().split('T')[0]
    const currentMonth = new Date().toISOString().slice(0, 7)

    // Cost limits
    const DAILY_LIMIT = 1.00
    const MONTHLY_LIMIT = 30.00

    // Get daily costs
    const { data: dailyCosts, error: dailyError } = await supabase
      .from('daily_llm_costs')
      .select('*')
      .eq('date', today)

    if (dailyError) {
      console.error('Daily costs query error:', dailyError)
    }

    const dailyTotal = dailyCosts?.reduce((sum, record) => 
      sum + parseFloat(record.total_cost_usd), 0) || 0

    // Get monthly costs
    const { data: monthlyCosts, error: monthlyError } = await supabase
      .from('monthly_llm_costs')
      .select('*')
      .gte('month', `${currentMonth}-01`)
      .lt('month', `${currentMonth}-31`)

    if (monthlyError) {
      console.error('Monthly costs query error:', monthlyError)
    }

    const monthlyTotal = monthlyCosts?.reduce((sum, record) => 
      sum + parseFloat(record.total_cost_usd), 0) || 0

    // Get breakdown by model for current month
    const breakdownByModel = monthlyCosts?.map(record => ({
      model: record.model,
      request_count: record.request_count,
      total_tokens: record.total_tokens,
      total_cost_usd: parseFloat(record.total_cost_usd)
    })) || []

    // Get recent requests (last 10)
    const { data: recentRequests, error: recentError } = await supabase
      .from('llm_costs')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(10)

    if (recentError) {
      console.error('Recent requests query error:', recentError)
    }

    const recent = recentRequests?.map(req => ({
      id: req.id,
      bookmark_id: req.bookmark_id,
      model: req.model,
      tokens: req.total_tokens,
      cost_usd: parseFloat(req.cost_usd),
      created_at: req.created_at,
      success: req.success
    })) || []

    // Check limits
    const { data: canProcessDaily } = await supabase
      .rpc('check_daily_cost_limit')
    
    const { data: canProcessMonthly } = await supabase
      .rpc('check_monthly_cost_limit')

    // Build response
    const costSummary: CostSummary = {
      daily: {
        date: today,
        total_cost_usd: dailyTotal,
        request_count: dailyCosts?.reduce((sum, r) => sum + r.request_count, 0) || 0,
        limit_usd: DAILY_LIMIT,
        remaining_usd: Math.max(0, DAILY_LIMIT - dailyTotal),
        percentage_used: (dailyTotal / DAILY_LIMIT) * 100
      },
      monthly: {
        month: currentMonth,
        total_cost_usd: monthlyTotal,
        request_count: monthlyCosts?.reduce((sum, r) => sum + r.request_count, 0) || 0,
        limit_usd: MONTHLY_LIMIT,
        remaining_usd: Math.max(0, MONTHLY_LIMIT - monthlyTotal),
        percentage_used: (monthlyTotal / MONTHLY_LIMIT) * 100
      },
      breakdown_by_model: breakdownByModel,
      recent_requests: recent,
      limits: {
        daily_limit_usd: DAILY_LIMIT,
        monthly_limit_usd: MONTHLY_LIMIT,
        is_daily_limit_reached: !canProcessDaily,
        is_monthly_limit_reached: !canProcessMonthly,
        can_process_new_request: canProcessDaily && canProcessMonthly
      }
    }

    return new Response(
      JSON.stringify(costSummary),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
    )

  } catch (error) {
    console.error('Function error:', error)
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error', 
        code: 'INTERNAL_ERROR',
        details: error.message 
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
    )
  }
})