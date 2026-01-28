import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatDate(date: string | Date): string {
  const d = typeof date === 'string' ? new Date(date) : date
  return new Intl.DateTimeFormat('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(d)
}

export function formatDateShort(date: string | Date): string {
  const d = typeof date === 'string' ? new Date(date) : date
  return new Intl.DateTimeFormat('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  }).format(d)
}

export function getStageColor(stage: number): string {
  const colors: Record<number, string> = {
    1: 'bg-stage-1',
    2: 'bg-stage-2',
    3: 'bg-stage-3',
    4: 'bg-stage-4',
    5: 'bg-stage-5',
  }
  return colors[stage] || colors[1]
}

export function getStageTextColor(stage: number): string {
  // Yellow and orange need dark text
  if (stage === 2 || stage === 3) return 'text-gray-900'
  return 'text-white'
}

export function getStageName(stage: number): string {
  const names: Record<number, string> = {
    1: 'Normal',
    2: 'Atencao',
    3: 'Alerta',
    4: 'Critico',
    5: 'Emergencia',
  }
  return names[stage] || 'Desconhecido'
}

export function getHeatColor(level: number): string {
  const colors: Record<number, string> = {
    1: 'bg-heat-1',
    2: 'bg-heat-2',
    3: 'bg-heat-3',
    4: 'bg-heat-4',
    5: 'bg-heat-5',
  }
  return colors[level] || colors[1]
}

export function getHeatTextColor(level: number): string {
  // Yellow needs dark text
  if (level === 3) return 'text-gray-900'
  return 'text-white'
}

export function getHeatName(level: number): string {
  const names: Record<number, string> = {
    1: 'Normal',
    2: 'Atencao',
    3: 'Alerta',
    4: 'Critico',
    5: 'Emergencia',
  }
  return names[level] || 'Desconhecido'
}

export function getSeverityColor(severity: string): string {
  const colors: Record<string, string> = {
    info: 'bg-severity-info',
    alert: 'bg-severity-alert',
    emergency: 'bg-severity-emergency',
  }
  return colors[severity] || colors.info
}

export function getSeverityName(severity: string): string {
  const names: Record<string, string> = {
    info: 'Informativo',
    alert: 'Alerta',
    emergency: 'Emergencia',
  }
  return names[severity] || severity
}

export function getStatusName(status: string): string {
  const names: Record<string, string> = {
    draft: 'Rascunho',
    sent: 'Enviado',
    canceled: 'Cancelado',
  }
  return names[status] || status
}
