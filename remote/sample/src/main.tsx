import {StrictMode} from 'react'
import {createRoot} from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import {ThemeProvider} from "@brick-lehm/xium-ui";
import {CssBaseline} from "@mui/material";

createRoot(document.getElementById('root')!).render(
    <StrictMode>
        <ThemeProvider defaultMode='light'>
            <CssBaseline />
            <App/>
        </ThemeProvider>
    </StrictMode>
)
