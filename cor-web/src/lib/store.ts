import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface AuthState {
  apiKey: string | null
  isAuthenticated: boolean
  setApiKey: (key: string) => void
  logout: () => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      apiKey: null,
      isAuthenticated: false,
      setApiKey: (key: string) => set({ apiKey: key, isAuthenticated: true }),
      logout: () => set({ apiKey: null, isAuthenticated: false }),
    }),
    {
      name: 'cor-auth',
    }
  )
)
