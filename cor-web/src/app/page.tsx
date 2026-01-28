'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useAuthStore } from '@/lib/store'
import { healthApi } from '@/lib/api'
import { Shield, AlertTriangle, CheckCircle } from 'lucide-react'

export default function LoginPage() {
  const [apiKey, setApiKey] = useState('')
  const [error, setError] = useState('')
  const [apiStatus, setApiStatus] = useState<'checking' | 'online' | 'offline'>('checking')
  const { setApiKey: storeApiKey, isAuthenticated } = useAuthStore()
  const router = useRouter()

  useEffect(() => {
    if (isAuthenticated) {
      router.push('/alerts')
    }
  }, [isAuthenticated, router])

  useEffect(() => {
    const checkApi = async () => {
      try {
        await healthApi.check()
        setApiStatus('online')
      } catch {
        setApiStatus('offline')
      }
    }
    checkApi()
  }, [])

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (!apiKey.trim()) {
      setError('Por favor, insira a API Key')
      return
    }
    storeApiKey(apiKey.trim())
    router.push('/alerts')
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="bg-cor-blue/50 backdrop-blur-sm rounded-2xl p-8 shadow-xl border border-white/10">
          <div className="text-center mb-8">
            <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-cor-orange/20 mb-4">
              <Shield className="w-8 h-8 text-cor-orange" />
            </div>
            <h1 className="text-2xl font-bold text-white">COR Alertas</h1>
            <p className="text-gray-400 mt-2">Centro de Operações Rio</p>
          </div>

          <div className="mb-6 flex items-center justify-center gap-2 text-sm">
            {apiStatus === 'checking' && (
              <span className="text-gray-400">Verificando API...</span>
            )}
            {apiStatus === 'online' && (
              <>
                <CheckCircle className="w-4 h-4 text-green-500" />
                <span className="text-green-500">API Online</span>
              </>
            )}
            {apiStatus === 'offline' && (
              <>
                <AlertTriangle className="w-4 h-4 text-red-500" />
                <span className="text-red-500">API Offline</span>
              </>
            )}
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label htmlFor="apiKey" className="block text-sm font-medium text-gray-300 mb-2">
                API Key
              </label>
              <input
                type="password"
                id="apiKey"
                value={apiKey}
                onChange={(e) => {
                  setApiKey(e.target.value)
                  setError('')
                }}
                className="w-full px-4 py-3 bg-cor-dark/50 border border-white/10 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-cor-orange focus:border-transparent transition-all"
                placeholder="Digite sua API Key"
              />
              {error && (
                <p className="mt-2 text-sm text-red-400">{error}</p>
              )}
            </div>

            <button
              type="submit"
              disabled={apiStatus === 'offline'}
              className="w-full py-3 px-4 bg-cor-orange hover:bg-cor-orange/90 disabled:bg-gray-600 disabled:cursor-not-allowed text-white font-semibold rounded-lg transition-colors focus:outline-none focus:ring-2 focus:ring-cor-orange focus:ring-offset-2 focus:ring-offset-cor-dark"
            >
              Entrar
            </button>
          </form>

          <p className="mt-6 text-center text-xs text-gray-500">
            Acesso restrito à equipe de comunicação
          </p>
        </div>
      </div>
    </div>
  )
}
