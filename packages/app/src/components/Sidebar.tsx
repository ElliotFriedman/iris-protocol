import { type FC } from 'react'
import { NavLink } from 'react-router-dom'
import { useAccount, useConnect, useDisconnect } from 'wagmi'
import { injected } from 'wagmi/connectors'
import {
  LayoutDashboard,
  Bot,
  KeyRound,
  Activity,
  Settings,
  LogOut,
  Wallet,
} from 'lucide-react'
import IrisAperture from './IrisAperture'
import { truncateAddress } from '../lib/utils'

const navItems = [
  { to: '/', icon: LayoutDashboard, label: 'Overview' },
  { to: '/agents', icon: Bot, label: 'My Agents' },
  { to: '/delegate', icon: KeyRound, label: 'Delegations' },
  { to: '/activity', icon: Activity, label: 'Activity Log' },
  { to: '/settings', icon: Settings, label: 'Settings' },
]

const Sidebar: FC = () => {
  const { address, isConnected } = useAccount()
  const { connect } = useConnect()
  const { disconnect } = useDisconnect()

  return (
    <aside
      className="fixed top-0 left-0 h-screen flex flex-col border-r border-graphite"
      style={{ width: 240, backgroundColor: 'var(--color-obsidian)' }}
    >
      {/* Logo */}
      <div className="flex items-center gap-3 px-5 py-5 border-b border-graphite">
        <IrisAperture tier={2} size={32} animated />
        <span className="font-mono text-base font-semibold text-bone tracking-tight">
          Iris Protocol
        </span>
      </div>

      {/* Wallet */}
      <div className="px-4 py-4 border-b border-graphite">
        {isConnected ? (
          <div className="flex flex-col gap-2">
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 rounded-full" style={{ backgroundColor: 'var(--color-mint)' }} />
              <span className="font-mono text-xs text-bone">
                {truncateAddress(address ?? '')}
              </span>
            </div>
            <button
              onClick={() => disconnect()}
              className="flex items-center gap-2 text-xs text-ash hover:text-bone transition-colors cursor-pointer"
            >
              <LogOut size={14} strokeWidth={1.5} />
              Disconnect
            </button>
          </div>
        ) : (
          <button
            onClick={() => connect({ connector: injected() })}
            className="w-full flex items-center justify-center gap-2 py-2 px-3 text-sm font-medium text-bone border border-graphite hover:border-iris transition-colors cursor-pointer"
            style={{ borderRadius: 6, backgroundColor: 'var(--color-void)' }}
          >
            <Wallet size={16} strokeWidth={1.5} />
            Connect Wallet
          </button>
        )}
      </div>

      {/* Navigation */}
      <nav className="flex-1 py-3 px-3 flex flex-col gap-0.5">
        {navItems.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            className={({ isActive }) =>
              `flex items-center gap-3 px-3 py-2.5 text-sm no-underline transition-colors ${
                isActive
                  ? 'text-bone'
                  : 'text-ash hover:text-bone'
              }`
            }
            style={({ isActive }) => ({
              borderRadius: 6,
              backgroundColor: isActive ? 'var(--color-graphite)' : 'transparent',
            })}
          >
            <Icon size={20} strokeWidth={1.5} />
            {label}
          </NavLink>
        ))}
      </nav>

      {/* Footer */}
      <div className="px-5 py-4 border-t border-graphite">
        <span className="font-mono text-xs text-ash">v0.1.0-alpha</span>
      </div>
    </aside>
  )
}

export default Sidebar
