import { type FC } from 'react'
import { Outlet } from 'react-router-dom'
import Sidebar from './Sidebar'
import ToastContainer from './ToastContainer'

const Layout: FC = () => {
  return (
    <div className="flex min-h-screen" style={{ backgroundColor: 'var(--color-void)' }}>
      <Sidebar />
      <main className="flex-1 min-h-screen" style={{ marginLeft: 240 }}>
        <div className="p-8 max-w-6xl">
          <Outlet />
        </div>
      </main>
      <ToastContainer />
    </div>
  )
}

export default Layout
