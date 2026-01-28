'use client'

import { useState, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import dynamic from 'next/dynamic'
import { useAuthStore } from '@/lib/store'
import { alertsApi, ApiError } from '@/lib/api'
import type { AlertArea, AlertCreate, AlertSeverity, CircleArea } from '@/types/alert'
import {
  AlertTriangle,
  AlertCircle,
  Info,
  ArrowLeft,
  Save,
  Send,
  Loader2,
  MapPin,
  Radio,
} from 'lucide-react'

// Dynamic import to avoid SSR issues with Leaflet
const AlertMap = dynamic(
  () => import('@/components/AlertMap').then((mod) => mod.AlertMap),
  { ssr: false, loading: () => <MapPlaceholder /> }
)

function MapPlaceholder() {
  return (
    <div className="w-full h-full min-h-[400px] bg-cor-dark/50 rounded-lg flex items-center justify-center">
      <Loader2 className="w-8 h-8 text-cor-orange animate-spin" />
    </div>
  )
}

const severityOptions: { value: AlertSeverity; label: string; icon: typeof Info; color: string }[] = [
  { value: 'info', label: 'Informativo', icon: Info, color: 'text-blue-400 border-blue-400' },
  { value: 'alert', label: 'Alerta', icon: AlertTriangle, color: 'text-yellow-400 border-yellow-400' },
  { value: 'emergency', label: 'Emergência', icon: AlertCircle, color: 'text-red-400 border-red-400' },
]

export default function NewAlertPage() {
  const router = useRouter()
  const { apiKey } = useAuthStore()

  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [severity, setSeverity] = useState<AlertSeverity>('alert')
  const [broadcast, setBroadcast] = useState(false)
  const [areas, setAreas] = useState<AlertArea[]>([])
  const [circles, setCircles] = useState<CircleArea[]>([])

  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const handleAreasChange = useCallback((newAreas: AlertArea[], newCircles: CircleArea[]) => {
    setAreas(newAreas)
    setCircles(newCircles)
  }, [])

  const validateForm = (): string | null => {
    if (!title.trim()) return 'Título é obrigatório'
    if (!body.trim()) return 'Mensagem é obrigatória'
    if (!broadcast && areas.length === 0 && circles.length === 0) {
      return 'Selecione uma área no mapa ou ative o modo Broadcast'
    }
    return null
  }

  const handleSave = async (sendImmediately: boolean = false) => {
    const validationError = validateForm()
    if (validationError) {
      setError(validationError)
      return
    }

    if (!apiKey) {
      setError('Sessão expirada. Por favor, faça login novamente.')
      return
    }

    setLoading(true)
    setError('')

    try {
      const alertData: AlertCreate = {
        title: title.trim(),
        body: body.trim(),
        severity,
        broadcast,
        areas: areas.length > 0 ? areas : undefined,
        circles: circles.length > 0 ? circles : undefined,
      }

      const alert = await alertsApi.create(apiKey, alertData)

      if (sendImmediately) {
        await alertsApi.send(apiKey, alert.id)
      }

      router.push('/alerts')
    } catch (err) {
      if (err instanceof ApiError) {
        setError(err.message)
      } else {
        setError('Erro ao criar alerta')
      }
    } finally {
      setLoading(false)
    }
  }

  const hasTargeting = broadcast || areas.length > 0 || circles.length > 0

  return (
    <div className="p-8">
      <div className="flex items-center gap-4 mb-8">
        <button
          onClick={() => router.back()}
          className="p-2 rounded-lg bg-white/5 hover:bg-white/10 text-gray-300 transition-colors"
        >
          <ArrowLeft className="w-5 h-5" />
        </button>
        <div>
          <h1 className="text-2xl font-bold text-white">Criar Alerta</h1>
          <p className="text-gray-400 mt-1">Configure e envie um novo alerta georreferenciado</p>
        </div>
      </div>

      {error && (
        <div className="mb-6 p-4 bg-red-500/10 border border-red-500/20 rounded-lg text-red-400">
          {error}
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Form Column */}
        <div className="space-y-6">
          {/* Severity */}
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-3">
              Severidade
            </label>
            <div className="flex gap-3">
              {severityOptions.map((option) => {
                const Icon = option.icon
                const isSelected = severity === option.value
                return (
                  <button
                    key={option.value}
                    type="button"
                    onClick={() => setSeverity(option.value)}
                    className={`flex-1 flex items-center justify-center gap-2 px-4 py-3 rounded-lg border-2 transition-all ${
                      isSelected
                        ? `${option.color} bg-white/5`
                        : 'border-white/10 text-gray-400 hover:border-white/20'
                    }`}
                  >
                    <Icon className="w-5 h-5" />
                    <span className="font-medium">{option.label}</span>
                  </button>
                )
              })}
            </div>
          </div>

          {/* Title */}
          <div>
            <label htmlFor="title" className="block text-sm font-medium text-gray-300 mb-2">
              Título
            </label>
            <input
              type="text"
              id="title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              maxLength={100}
              className="w-full px-4 py-3 bg-cor-dark/50 border border-white/10 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-cor-orange focus:border-transparent transition-all"
              placeholder="Ex: Alerta de Chuva Forte"
            />
            <p className="mt-1 text-xs text-gray-500">{title.length}/100 caracteres</p>
          </div>

          {/* Body */}
          <div>
            <label htmlFor="body" className="block text-sm font-medium text-gray-300 mb-2">
              Mensagem
            </label>
            <textarea
              id="body"
              value={body}
              onChange={(e) => setBody(e.target.value)}
              rows={4}
              maxLength={500}
              className="w-full px-4 py-3 bg-cor-dark/50 border border-white/10 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-cor-orange focus:border-transparent transition-all resize-none"
              placeholder="Descreva o alerta para os cidadãos..."
            />
            <p className="mt-1 text-xs text-gray-500">{body.length}/500 caracteres</p>
          </div>

          {/* Broadcast Toggle */}
          <div className="flex items-center justify-between p-4 bg-cor-dark/30 rounded-lg border border-white/10">
            <div className="flex items-center gap-3">
              <Radio className="w-5 h-5 text-purple-400" />
              <div>
                <p className="font-medium text-white">Broadcast</p>
                <p className="text-xs text-gray-400">Enviar para todos os dispositivos</p>
              </div>
            </div>
            <button
              type="button"
              onClick={() => setBroadcast(!broadcast)}
              className={`relative w-12 h-6 rounded-full transition-colors ${
                broadcast ? 'bg-purple-500' : 'bg-gray-600'
              }`}
            >
              <span
                className={`absolute top-1 w-4 h-4 bg-white rounded-full transition-transform ${
                  broadcast ? 'left-7' : 'left-1'
                }`}
              />
            </button>
          </div>

          {/* Targeting Summary */}
          <div className="p-4 bg-cor-dark/30 rounded-lg border border-white/10">
            <div className="flex items-center gap-2 mb-2">
              <MapPin className="w-4 h-4 text-cor-orange" />
              <span className="font-medium text-white">Segmentação</span>
            </div>
            {broadcast ? (
              <p className="text-sm text-purple-400">Broadcast ativado - todos os dispositivos</p>
            ) : areas.length > 0 || circles.length > 0 ? (
              <p className="text-sm text-green-400">
                {areas.length} polígono(s), {circles.length} círculo(s) selecionado(s)
              </p>
            ) : (
              <p className="text-sm text-yellow-400">
                Desenhe uma área no mapa ou ative o Broadcast
              </p>
            )}
          </div>

          {/* Action Buttons */}
          <div className="flex gap-4 pt-4">
            <button
              type="button"
              onClick={() => handleSave(false)}
              disabled={loading || !hasTargeting}
              className="flex-1 flex items-center justify-center gap-2 px-6 py-3 bg-white/10 hover:bg-white/20 disabled:bg-gray-700 disabled:cursor-not-allowed text-white font-semibold rounded-lg transition-colors"
            >
              {loading ? (
                <Loader2 className="w-5 h-5 animate-spin" />
              ) : (
                <Save className="w-5 h-5" />
              )}
              Salvar Rascunho
            </button>
            <button
              type="button"
              onClick={() => handleSave(true)}
              disabled={loading || !hasTargeting}
              className="flex-1 flex items-center justify-center gap-2 px-6 py-3 bg-green-600 hover:bg-green-700 disabled:bg-gray-700 disabled:cursor-not-allowed text-white font-semibold rounded-lg transition-colors"
            >
              {loading ? (
                <Loader2 className="w-5 h-5 animate-spin" />
              ) : (
                <Send className="w-5 h-5" />
              )}
              Enviar Agora
            </button>
          </div>
        </div>

        {/* Map Column */}
        <div className="bg-cor-blue/30 backdrop-blur-sm border border-white/10 rounded-xl p-4">
          <div className="flex items-center gap-2 mb-4">
            <MapPin className="w-5 h-5 text-cor-orange" />
            <h2 className="font-semibold text-white">Área de Abrangência</h2>
          </div>
          <p className="text-sm text-gray-400 mb-4">
            Use as ferramentas de desenho para definir polígonos ou círculos.
            Clique no ícone de polígono ou círculo no canto superior direito do mapa.
          </p>
          <div className="h-[500px]">
            <AlertMap onAreasChange={handleAreasChange} />
          </div>
        </div>
      </div>
    </div>
  )
}
