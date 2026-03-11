import { http, createConfig } from 'wagmi'
import { localhost, sepolia } from 'wagmi/chains'

export const config = createConfig({
  chains: [localhost, sepolia],
  transports: {
    [localhost.id]: http('http://127.0.0.1:8545'),
    [sepolia.id]: http(),
  },
})

declare module 'wagmi' {
  interface Register {
    config: typeof config
  }
}
