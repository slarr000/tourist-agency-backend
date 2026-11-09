import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App' // Убрали расширение .jsx, Vite сам найдет .tsx
import './styles.css'

document.documentElement.dataset.theme = localStorage.getItem('is-tour-theme') === 'light' ? 'light' : 'dark';

// Добавили проверку на null (TS требует этого)
const rootElement = document.getElementById('root');
if (rootElement) {
  createRoot(rootElement).render(
    <StrictMode>
      <App />
    </StrictMode>,
  )
}