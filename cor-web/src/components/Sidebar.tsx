'use client'

import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import { useAuthStore } from '@/lib/store'
import {
  Bell,
  PlusCircle,
  LogOut,
  Shield,
  LayoutDashboard
} from 'lucide-react'

const navItems = [
  { href: '/alerts', label: 'Alertas', icon: Bell },
  { href: '/alerts/new', label: 'Criar Alerta', icon: PlusCircle },
]

export function Sidebar() {
  const pathname = usePathname()
  const router = useRouter()
  const { logout } = useAuthStore()

  const handleLogout = () => {
    logout()
    router.push('/')
  }

  return (
    <aside className="w-64 bg-cor-blue/50 backdrop-blur-sm border-r border-white/10 flex flex-col">
      <div className="p-6 border-b border-white/10">
        <Link href="/alerts" className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-cor-orange/20 flex items-center justify-center">
            <Shield className="w-5 h-5 text-cor-orange" />
          </div>
          <div>
            <h1 className="font-bold text-white">COR Alertas</h1>
            <p className="text-xs text-gray-400">Painel de Operações</p>
          </div>
        </Link>
      </div>

      <nav className="flex-1 p-4">
        <ul className="space-y-2">
          {navItems.map((item) => {
            const Icon = item.icon
            const isActive = pathname === item.href
            return (
              <li key={item.href}>
                <Link
                  href={item.href}
                  className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-all ${
                    isActive
                      ? 'bg-cor-orange text-white'
                      : 'text-gray-300 hover:bg-white/5 hover:text-white'
                  }`}
                >
                  <Icon className="w-5 h-5" />
                  <span className="font-medium">{item.label}</span>
                </Link>
              </li>
            )
          })}
        </ul>
      </nav>

      <div className="p-4 border-t border-white/10">
        <button
          onClick={handleLogout}
          className="flex items-center gap-3 px-4 py-3 w-full rounded-lg text-gray-300 hover:bg-red-500/10 hover:text-red-400 transition-all"
        >
          <LogOut className="w-5 h-5" />
          <span className="font-medium">Sair</span>
        </button>
      </div>
    </aside>
  )
}
