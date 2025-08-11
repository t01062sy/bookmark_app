import { createContext, useContext, useState, useEffect, type ReactNode } from 'react'
import { webAuthnService, isWebAuthnSupported } from '../lib/webauthn'

interface User {
  id: string
  name: string
  createdAt: string
}

interface AuthContextType {
  user: User | null
  isAuthenticated: boolean
  isLoading: boolean
  webAuthnSupported: boolean
  register: (name: string) => Promise<void>
  login: () => Promise<void>
  logout: () => void
  error: string | null
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const webAuthnSupported = isWebAuthnSupported()

  // Check for existing session on mount
  useEffect(() => {
    const storedUser = localStorage.getItem('bookmark_app_user')
    if (storedUser) {
      try {
        setUser(JSON.parse(storedUser))
      } catch (e) {
        console.error('Failed to parse stored user:', e)
      }
    }
    setIsLoading(false)
  }, [])

  // Register new user with WebAuthn
  const register = async (name: string) => {
    setError(null)
    setIsLoading(true)

    try {
      if (!webAuthnSupported) {
        throw new Error('WebAuthn is not supported in your browser. Please use a modern browser.')
      }

      // Generate a unique user ID
      const userId = crypto.randomUUID()
      
      // Register WebAuthn credential
      await webAuthnService.register({
        userId,
        userName: name,
        userDisplayName: name,
      })

      // Create user object
      const newUser: User = {
        id: userId,
        name,
        createdAt: new Date().toISOString(),
      }

      // Save user to localStorage
      localStorage.setItem('bookmark_app_user', JSON.stringify(newUser))
      localStorage.setItem('bookmark_app_session', 'active')
      
      setUser(newUser)
    } catch (err) {
      console.error('Registration failed:', err)
      setError(err instanceof Error ? err.message : 'Registration failed')
      throw err
    } finally {
      setIsLoading(false)
    }
  }

  // Login with existing WebAuthn credential
  const login = async () => {
    setError(null)
    setIsLoading(true)

    try {
      if (!webAuthnSupported) {
        throw new Error('WebAuthn is not supported in your browser. Please use a modern browser.')
      }

      // Get stored user info first to check if user exists
      const storedUser = localStorage.getItem('bookmark_app_user')
      if (!storedUser) {
        // More helpful error message
        throw new Error('No account found in this browser. Please create a new account first.')
      }

      // Authenticate with WebAuthn
      await webAuthnService.authenticate()

      const user = JSON.parse(storedUser)
      
      // Update session
      localStorage.setItem('bookmark_app_session', 'active')
      setUser(user)
    } catch (err) {
      console.error('Login failed:', err)
      setError(err instanceof Error ? err.message : 'Login failed')
      throw err
    } finally {
      setIsLoading(false)
    }
  }

  // Logout
  const logout = () => {
    localStorage.removeItem('bookmark_app_session')
    setUser(null)
    setError(null)
  }

  const value: AuthContextType = {
    user,
    isAuthenticated: !!user,
    isLoading,
    webAuthnSupported,
    register,
    login,
    logout,
    error,
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

// Hook to use auth context
export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}

// Protected route component
export function RequireAuth({ children }: { children: ReactNode }) {
  const { isAuthenticated, isLoading } = useAuth()

  if (isLoading) {
    return (
      <div className="loading">
        <p>⏳ Loading...</p>
      </div>
    )
  }

  if (!isAuthenticated) {
    return null // Auth component will be shown instead
  }

  return <>{children}</>
}