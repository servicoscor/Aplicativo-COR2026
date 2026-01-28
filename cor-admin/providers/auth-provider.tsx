'use client'

import { createContext, useContext, useEffect, useState, useCallback } from 'react'
import { useRouter, usePathname } from 'next/navigation'
import { apiClient } from '@/lib/api/client'
import type { AdminUser, TokenResponse } from '@/types/api'

interface AuthContextType {
  user: AdminUser | null
  isLoading: boolean
  isAuthenticated: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => void
  refreshUser: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

const PUBLIC_PATHS = ['/login']

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<AdminUser | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const router = useRouter()
  const pathname = usePathname()

  const isAuthenticated = !!user

  const logout = useCallback(() => {
    apiClient.clearToken()
    setUser(null)
    router.push('/login')
  }, [router])

  const refreshUser = useCallback(async () => {
    try {
      const response = await apiClient.getMe()
      setUser(response.data)
    } catch (error) {
      logout()
    }
  }, [logout])

  const login = useCallback(async (email: string, password: string) => {
    const response = await apiClient.login(email, password)
    setUser(response.user)
    router.push('/dashboard')
  }, [router])

  // Check authentication on mount
  useEffect(() => {
    const checkAuth = async () => {
      const token = apiClient.getToken()

      if (!token) {
        setIsLoading(false)
        if (!PUBLIC_PATHS.includes(pathname)) {
          router.push('/login')
        }
        return
      }

      try {
        const response = await apiClient.getMe()
        setUser(response.data)
      } catch (error) {
        apiClient.clearToken()
        if (!PUBLIC_PATHS.includes(pathname)) {
          router.push('/login')
        }
      } finally {
        setIsLoading(false)
      }
    }

    checkAuth()
  }, [pathname, router])

  // Redirect if accessing protected route without auth
  useEffect(() => {
    if (!isLoading && !isAuthenticated && !PUBLIC_PATHS.includes(pathname)) {
      router.push('/login')
    }
  }, [isLoading, isAuthenticated, pathname, router])

  return (
    <AuthContext.Provider
      value={{
        user,
        isLoading,
        isAuthenticated,
        login,
        logout,
        refreshUser,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}
