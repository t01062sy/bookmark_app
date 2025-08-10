import {
  startAuthentication,
  startRegistration,
  browserSupportsWebAuthn,
} from '@simplewebauthn/browser'
import type {
  PublicKeyCredentialCreationOptionsJSON,
  PublicKeyCredentialRequestOptionsJSON,
  RegistrationResponseJSON,
  AuthenticationResponseJSON,
} from '@simplewebauthn/types'

// Check if WebAuthn is supported
export const isWebAuthnSupported = () => browserSupportsWebAuthn()

// WebAuthn configuration
const RP_NAME = 'Bookmark App'
const RP_ID = window.location.hostname === 'localhost' ? 'localhost' : window.location.hostname

// Types for our WebAuthn implementation
export interface WebAuthnCredential {
  id: string
  public_key: string
  counter: number
  created_at: string
  last_used_at?: string
  device_name?: string
}

export interface WebAuthnRegistrationOptions {
  userId: string
  userName: string
  userDisplayName?: string
}

export interface WebAuthnAuthenticationOptions {
  userId?: string
}

// WebAuthn API service
export const webAuthnService = {
  // Generate registration options
  async generateRegistrationOptions(options: WebAuthnRegistrationOptions): Promise<PublicKeyCredentialCreationOptionsJSON> {
    // In production, this would call your backend API
    // For now, we'll generate options client-side for testing
    
    const challenge = new Uint8Array(32)
    crypto.getRandomValues(challenge)
    
    return {
      challenge: btoa(String.fromCharCode(...challenge)),
      rp: {
        name: RP_NAME,
        id: RP_ID,
      },
      user: {
        id: btoa(options.userId),
        name: options.userName,
        displayName: options.userDisplayName || options.userName,
      },
      pubKeyCredParams: [
        { alg: -7, type: 'public-key' },   // ES256
        { alg: -257, type: 'public-key' }, // RS256
      ],
      authenticatorSelection: {
        authenticatorAttachment: 'platform', // Use platform authenticator (Touch ID, Face ID, Windows Hello)
        requireResidentKey: true,
        residentKey: 'required',
        userVerification: 'required',
      },
      timeout: 60000,
      attestation: 'none', // We don't need attestation for this use case
    }
  },

  // Register a new credential
  async register(options: WebAuthnRegistrationOptions): Promise<RegistrationResponseJSON> {
    if (!isWebAuthnSupported()) {
      throw new Error('WebAuthn is not supported in this browser')
    }

    try {
      // Generate registration options
      const publicKeyOptions = await this.generateRegistrationOptions(options)
      
      // Start registration process
      const registrationResponse = await startRegistration({ optionsJSON: publicKeyOptions })
      
      // In production, send this response to your backend for verification
      // For now, we'll store it locally
      this.saveCredential(options.userId, registrationResponse)
      
      return registrationResponse
    } catch (error) {
      console.error('Registration failed:', error)
      throw error
    }
  },

  // Generate authentication options
  async generateAuthenticationOptions(options?: WebAuthnAuthenticationOptions): Promise<PublicKeyCredentialRequestOptionsJSON> {
    // In production, this would call your backend API
    const challenge = new Uint8Array(32)
    crypto.getRandomValues(challenge)
    
    return {
      challenge: btoa(String.fromCharCode(...challenge)),
      rpId: RP_ID,
      userVerification: 'required',
      timeout: 60000,
      // In production, you'd fetch allowed credentials from the backend
      // For testing, we'll use credentials from localStorage
      allowCredentials: options?.userId ? this.getStoredCredentials(options.userId) : undefined,
    }
  },

  // Authenticate with existing credential
  async authenticate(options?: WebAuthnAuthenticationOptions): Promise<AuthenticationResponseJSON> {
    if (!isWebAuthnSupported()) {
      throw new Error('WebAuthn is not supported in this browser')
    }

    try {
      // Generate authentication options
      const publicKeyOptions = await this.generateAuthenticationOptions(options)
      
      // Start authentication process
      const authenticationResponse = await startAuthentication({ optionsJSON: publicKeyOptions })
      
      // In production, send this response to your backend for verification
      // For now, we'll just validate locally
      const isValid = this.verifyAuthentication(authenticationResponse)
      
      if (!isValid) {
        throw new Error('Authentication failed')
      }
      
      return authenticationResponse
    } catch (error) {
      console.error('Authentication failed:', error)
      throw error
    }
  },

  // Helper: Save credential to localStorage (for testing)
  saveCredential(userId: string, credential: RegistrationResponseJSON) {
    const credentials = JSON.parse(localStorage.getItem('webauthn_credentials') || '{}')
    
    if (!credentials[userId]) {
      credentials[userId] = []
    }
    
    credentials[userId].push({
      id: credential.id,
      rawId: credential.rawId,
      type: credential.type,
      response: {
        publicKey: credential.response.publicKey,
        authenticatorData: credential.response.authenticatorData,
      },
      created_at: new Date().toISOString(),
    })
    
    localStorage.setItem('webauthn_credentials', JSON.stringify(credentials))
  },

  // Helper: Get stored credentials from localStorage (for testing)
  getStoredCredentials(userId: string) {
    const credentials = JSON.parse(localStorage.getItem('webauthn_credentials') || '{}')
    const userCredentials = credentials[userId] || []
    
    return userCredentials.map((cred: any) => ({
      id: cred.id,
      type: 'public-key' as const,
    }))
  },

  // Helper: Verify authentication (simplified for testing)
  verifyAuthentication(response: AuthenticationResponseJSON): boolean {
    // In production, this verification would happen on the backend
    // For testing, we'll just check if the response has the expected fields
    return !!(
      response.id &&
      response.rawId &&
      response.response &&
      response.response.authenticatorData &&
      response.response.signature
    )
  },

  // Check if user has registered credentials
  hasCredentials(userId: string): boolean {
    const credentials = JSON.parse(localStorage.getItem('webauthn_credentials') || '{}')
    return !!(credentials[userId] && credentials[userId].length > 0)
  },

  // Clear all stored credentials (for testing)
  clearCredentials() {
    localStorage.removeItem('webauthn_credentials')
  },
}