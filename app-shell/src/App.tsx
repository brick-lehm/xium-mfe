import {ThemeProvider} from "@brick-lehm/xium-ui";
import Sample from "sample/Sample";

function App() {

    return (
        <ThemeProvider defaultMode='light'>
            <main className="container mx-auto px-4 py-8">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                    <Sample title='loading host' />
                </div>
            </main>
        </ThemeProvider>
    )
}

export default App
