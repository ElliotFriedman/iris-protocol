import { type FC, useEffect, useState, createContext, useContext, useCallback, type ReactNode } from 'react'
import { CheckCircle, AlertTriangle, XCircle, X, Info } from 'lucide-react'

type ToastType = 'success' | 'error' | 'warning' | 'info'

interface Toast {
  id: string
  type: ToastType
  message: string
}

interface ToastContextType {
  addToast: (type: ToastType, message: string) => void
}

const ToastContext = createContext<ToastContextType>({ addToast: () => {} })

export function useToast() {
  return useContext(ToastContext)
}

const borderColors: Record<ToastType, string> = {
  success: 'var(--color-mint)',
  error: 'var(--color-signal-red)',
  warning: 'var(--color-amber)',
  info: 'var(--color-cyan)',
}

const icons: Record<ToastType, FC<{ size: number; strokeWidth: number }>> = {
  success: CheckCircle,
  error: XCircle,
  warning: AlertTriangle,
  info: Info,
}

function ToastItem({ toast, onRemove }: { toast: Toast; onRemove: () => void }) {
  const Icon = icons[toast.type]

  useEffect(() => {
    const timer = setTimeout(onRemove, 4000)
    return () => clearTimeout(timer)
  }, [onRemove])

  return (
    <div
      className="flex items-center gap-3 px-4 py-3 border border-graphite"
      style={{
        backgroundColor: 'var(--color-obsidian)',
        borderRadius: 8,
        borderLeftWidth: 3,
        borderLeftColor: borderColors[toast.type],
        minWidth: 300,
      }}
    >
      <Icon size={18} strokeWidth={1.5} />
      <span className="flex-1 text-sm text-bone">{toast.message}</span>
      <button onClick={onRemove} className="text-ash hover:text-bone cursor-pointer bg-transparent border-0 p-0">
        <X size={14} strokeWidth={1.5} />
      </button>
    </div>
  )
}

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([])

  const addToast = useCallback((type: ToastType, message: string) => {
    const id = Math.random().toString(36).slice(2)
    setToasts((prev) => [...prev, { id, type, message }])
  }, [])

  const removeToast = useCallback((id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id))
  }, [])

  return (
    <ToastContext.Provider value={{ addToast }}>
      {children}
      <div className="fixed bottom-6 right-6 flex flex-col gap-2" style={{ zIndex: 50 }}>
        {toasts.map((toast) => (
          <ToastItem key={toast.id} toast={toast} onRemove={() => removeToast(toast.id)} />
        ))}
      </div>
    </ToastContext.Provider>
  )
}

const ToastContainer: FC = () => null
export default ToastContainer
