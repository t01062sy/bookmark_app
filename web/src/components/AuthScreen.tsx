import { useState } from 'react'
import { useAuth } from '../contexts/AuthContext'
import './AuthScreen.css'

export function AuthScreen() {
  const { register, login, webAuthnSupported, error } = useAuth()
  const [mode, setMode] = useState<'welcome' | 'register' | 'login'>('welcome')
  const [name, setName] = useState('')
  const [isProcessing, setIsProcessing] = useState(false)

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!name.trim()) return

    setIsProcessing(true)
    try {
      await register(name.trim())
    } catch (err) {
      // Error is handled in context
    } finally {
      setIsProcessing(false)
    }
  }

  const handleLogin = async () => {
    setIsProcessing(true)
    try {
      await login()
    } catch (err) {
      // Error is handled in context
    } finally {
      setIsProcessing(false)
    }
  }

  if (!webAuthnSupported) {
    return (
      <div className="auth-screen">
        <div className="auth-container">
          <div className="auth-card">
            <div className="auth-icon">⚠️</div>
            <h1>Browser Not Supported</h1>
            <p className="auth-description">
              Your browser doesn't support passkey authentication.
              Please use a modern browser like Chrome, Safari, Firefox, or Edge.
            </p>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="auth-screen">
      <div className="auth-container">
        <div className="auth-card">
          {mode === 'welcome' && (
            <>
              <div className="auth-icon">🔐</div>
              <h1>Welcome to Bookmark App</h1>
              <p className="auth-description">
                Secure, private bookmark management with AI-powered organization.
                Sign in with your device's passkey for enhanced security.
              </p>
              
              <div className="auth-buttons">
                <button 
                  className="auth-button primary"
                  onClick={() => setMode('login')}
                >
                  🔑 Sign In with Passkey
                </button>
                <button 
                  className="auth-button secondary"
                  onClick={() => setMode('register')}
                >
                  ✨ Create New Account
                </button>
              </div>

              <div className="auth-features">
                <div className="feature">
                  <span className="feature-icon">🛡️</span>
                  <div>
                    <h3>Secure</h3>
                    <p>End-to-end encryption with device passkeys</p>
                  </div>
                </div>
                <div className="feature">
                  <span className="feature-icon">🤖</span>
                  <div>
                    <h3>AI-Powered</h3>
                    <p>Automatic summarization and categorization</p>
                  </div>
                </div>
                <div className="feature">
                  <span className="feature-icon">🔍</span>
                  <div>
                    <h3>Smart Search</h3>
                    <p>Semantic search to find what you need</p>
                  </div>
                </div>
              </div>
            </>
          )}

          {mode === 'register' && (
            <>
              <div className="auth-icon">✨</div>
              <h1>Create Account</h1>
              <p className="auth-description">
                Set up your secure passkey to get started
              </p>

              <form onSubmit={handleRegister} className="auth-form">
                <div className="form-group">
                  <label htmlFor="name">Your Name</label>
                  <input
                    id="name"
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="Enter your name"
                    required
                    disabled={isProcessing}
                    autoFocus
                  />
                </div>

                {error && (
                  <div className="auth-error">
                    ❌ {error}
                  </div>
                )}

                <button 
                  type="submit" 
                  className="auth-button primary"
                  disabled={isProcessing || !name.trim()}
                >
                  {isProcessing ? '⏳ Setting up passkey...' : '🔑 Create Passkey'}
                </button>
              </form>

              <button 
                className="auth-link"
                onClick={() => setMode('welcome')}
                disabled={isProcessing}
              >
                ← Back
              </button>
            </>
          )}

          {mode === 'login' && (
            <>
              <div className="auth-icon">🔑</div>
              <h1>Welcome Back</h1>
              <p className="auth-description">
                Use your device's passkey to sign in
              </p>

              {error && (
                <div className="auth-error">
                  ❌ {error}
                </div>
              )}

              <button 
                className="auth-button primary"
                onClick={handleLogin}
                disabled={isProcessing}
              >
                {isProcessing ? '⏳ Authenticating...' : '🔓 Unlock with Passkey'}
              </button>

              <div className="auth-divider">
                <span>New here?</span>
              </div>

              <button 
                className="auth-button secondary"
                onClick={() => setMode('register')}
                disabled={isProcessing}
              >
                Create New Account
              </button>

              <button 
                className="auth-link"
                onClick={() => setMode('welcome')}
                disabled={isProcessing}
              >
                ← Back
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  )
}