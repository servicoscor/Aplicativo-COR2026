'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from '@/lib/api/client'
import { useAuth } from '@/providers/auth-provider'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import DynamicMap, { type GeoArea } from '@/components/map/DynamicMap'
import { cn } from '@/lib/utils'
import {
  AlertCircle,
  ArrowLeft,
  Bell,
  Globe,
  Loader2,
  MapPin,
  Send,
  Save,
} from 'lucide-react'

const SEVERITY_OPTIONS = [
  {
    value: 'info',
    label: 'Informativo',
    color: 'bg-blue-100 text-blue-800 border-blue-300',
    description: 'Informacoes gerais e avisos',
  },
  {
    value: 'alert',
    label: 'Alerta',
    color: 'bg-yellow-100 text-yellow-800 border-yellow-300',
    description: 'Situacao de atencao',
  },
  {
    value: 'emergency',
    label: 'Emergencia',
    color: 'bg-red-100 text-red-800 border-red-300',
    description: 'Situacao critica, acao imediata',
  },
]

export default function NewAlertPage() {
  const { user } = useAuth()
  const router = useRouter()
  const queryClient = useQueryClient()

  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [severity, setSeverity] = useState('info')
  const [isBroadcast, setIsBroadcast] = useState(true)
  const [geoArea, setGeoArea] = useState<GeoArea | null>(null)
  const [error, setError] = useState('')

  const canCreate = user?.role === 'admin' || user?.role === 'comunicacao'

  if (!canCreate) {
    router.push('/alerts')
    return null
  }

  const createMutation = useMutation({
    mutationFn: (sendImmediately: boolean) => {
      const payload: any = {
        title,
        body,
        severity,
        is_broadcast: isBroadcast,
      }

      if (!isBroadcast && geoArea) {
        if (geoArea.type === 'circle') {
          payload.target_center_lat = (geoArea.coordinates as number[])[0]
          payload.target_center_lng = (geoArea.coordinates as number[])[1]
          payload.target_radius = geoArea.radius
        } else if (geoArea.type === 'polygon') {
          payload.target_polygon = geoArea.coordinates
        }
      }

      return apiClient.createAlert(payload, sendImmediately)
    },
    onSuccess: (_, sendImmediately) => {
      queryClient.invalidateQueries({ queryKey: ['alerts'] })
      router.push('/alerts')
    },
    onError: (err: any) => {
      setError(err.response?.data?.detail || 'Erro ao criar alerta')
    },
  })

  const handleSubmit = (sendImmediately: boolean) => {
    setError('')

    if (!title.trim()) {
      setError('Titulo e obrigatorio')
      return
    }

    if (!body.trim()) {
      setError('Corpo do alerta e obrigatorio')
      return
    }

    if (!isBroadcast && !geoArea) {
      setError('Selecione uma area no mapa ou ative o broadcast')
      return
    }

    createMutation.mutate(sendImmediately)
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Link href="/alerts">
          <Button variant="ghost" size="sm">
            <ArrowLeft className="w-4 h-4 mr-2" />
            Voltar
          </Button>
        </Link>
        <h1 className="text-2xl font-bold text-gray-900">Novo Alerta</h1>
      </div>

      {error && (
        <div className="flex items-center gap-2 p-4 text-sm text-red-600 bg-red-50 rounded-lg border border-red-200">
          <AlertCircle className="w-5 h-5" />
          {error}
        </div>
      )}

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Alert Form */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Bell className="w-5 h-5" />
              Informacoes do Alerta
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="title">Titulo *</Label>
              <Input
                id="title"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Ex: Alerta de chuva forte"
                maxLength={200}
              />
              <p className="text-xs text-gray-500">
                {title.length}/200 caracteres
              </p>
            </div>

            <div className="space-y-2">
              <Label htmlFor="body">Mensagem *</Label>
              <textarea
                id="body"
                value={body}
                onChange={(e) => setBody(e.target.value)}
                placeholder="Ex: Previsao de chuva forte nas proximas horas. Evite areas de risco..."
                rows={4}
                maxLength={1000}
                className="flex w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
              />
              <p className="text-xs text-gray-500">
                {body.length}/1000 caracteres
              </p>
            </div>

            <div className="space-y-2">
              <Label>Severidade *</Label>
              <div className="grid gap-2">
                {SEVERITY_OPTIONS.map((opt) => (
                  <button
                    key={opt.value}
                    type="button"
                    onClick={() => setSeverity(opt.value)}
                    className={cn(
                      'flex items-center gap-3 p-3 rounded-lg border-2 text-left transition-all',
                      severity === opt.value
                        ? opt.color + ' border-current'
                        : 'bg-white border-gray-200 hover:border-gray-300'
                    )}
                  >
                    <div
                      className={cn(
                        'w-4 h-4 rounded-full border-2',
                        severity === opt.value
                          ? 'bg-current border-current'
                          : 'border-gray-300'
                      )}
                    />
                    <div>
                      <p className="font-medium">{opt.label}</p>
                      <p className="text-xs opacity-80">{opt.description}</p>
                    </div>
                  </button>
                ))}
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Target Area */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <MapPin className="w-5 h-5" />
              Area de Destino
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => setIsBroadcast(true)}
                className={cn(
                  'flex-1 flex items-center justify-center gap-2 p-3 rounded-lg border-2 transition-all',
                  isBroadcast
                    ? 'bg-blue-50 border-blue-500 text-blue-700'
                    : 'bg-white border-gray-200 hover:border-gray-300'
                )}
              >
                <Globe className="w-5 h-5" />
                <span className="font-medium">Toda a Cidade</span>
              </button>
              <button
                type="button"
                onClick={() => setIsBroadcast(false)}
                className={cn(
                  'flex-1 flex items-center justify-center gap-2 p-3 rounded-lg border-2 transition-all',
                  !isBroadcast
                    ? 'bg-blue-50 border-blue-500 text-blue-700'
                    : 'bg-white border-gray-200 hover:border-gray-300'
                )}
              >
                <MapPin className="w-5 h-5" />
                <span className="font-medium">Area Especifica</span>
              </button>
            </div>

            {isBroadcast ? (
              <div className="p-4 bg-blue-50 rounded-lg text-sm text-blue-700">
                <p className="font-medium">Alerta para toda a cidade</p>
                <p className="mt-1 opacity-80">
                  Todos os usuarios receberao esta notificacao, independente da
                  localizacao.
                </p>
              </div>
            ) : (
              <>
                <p className="text-sm text-gray-500">
                  Desenhe um circulo ou poligono no mapa para definir a area
                  afetada. Somente usuarios nesta area receberao o alerta.
                </p>
                <DynamicMap
                  onAreaChange={setGeoArea}
                  initialArea={geoArea}
                />
                {geoArea && (
                  <div className="p-3 bg-green-50 rounded-lg text-sm text-green-700">
                    <p className="font-medium">Area selecionada</p>
                    <p className="mt-1 opacity-80">
                      Tipo: {geoArea.type === 'circle' ? 'Circulo' : 'Poligono'}
                      {geoArea.type === 'circle' &&
                        geoArea.radius &&
                        ` - Raio: ${(geoArea.radius / 1000).toFixed(1)}km`}
                    </p>
                  </div>
                )}
              </>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Preview */}
      <Card>
        <CardHeader>
          <CardTitle>Preview da Notificacao</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="max-w-md mx-auto">
            <div className="bg-white rounded-xl shadow-lg border overflow-hidden">
              <div className="p-4 bg-gray-50 border-b flex items-center gap-2">
                <div className="w-8 h-8 bg-blue-600 rounded-full flex items-center justify-center">
                  <span className="text-xs font-bold text-white">COR</span>
                </div>
                <div>
                  <p className="text-sm font-medium">COR.Rio</p>
                  <p className="text-xs text-gray-500">agora</p>
                </div>
              </div>
              <div className="p-4">
                <p className="font-semibold text-gray-900">
                  {title || 'Titulo do alerta'}
                </p>
                <p className="mt-1 text-sm text-gray-600 line-clamp-3">
                  {body || 'Mensagem do alerta aparecera aqui...'}
                </p>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Actions */}
      <div className="flex justify-end gap-3">
        <Link href="/alerts">
          <Button variant="outline">Cancelar</Button>
        </Link>
        <Button
          variant="outline"
          onClick={() => handleSubmit(false)}
          disabled={createMutation.isPending}
        >
          {createMutation.isPending ? (
            <Loader2 className="w-4 h-4 mr-2 animate-spin" />
          ) : (
            <Save className="w-4 h-4 mr-2" />
          )}
          Salvar Rascunho
        </Button>
        <Button
          onClick={() => handleSubmit(true)}
          disabled={createMutation.isPending}
        >
          {createMutation.isPending ? (
            <Loader2 className="w-4 h-4 mr-2 animate-spin" />
          ) : (
            <Send className="w-4 h-4 mr-2" />
          )}
          Enviar Agora
        </Button>
      </div>
    </div>
  )
}
