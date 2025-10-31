import Sample from "./exposes/Sample.tsx";

/**
 * 開発プレビュー
 * @constructor
 */
function App() {
    return (
        <main className="st:container st:mx-auto st:px-4 st:py-8">
            <div className="st:grid st:grid-cols-1 st:md:grid-cols-2 st:gap-8">
                <div className="st:space-y-6">
                    <Sample title='sample button' />
                </div>
            </div>
        </main>
    )
}

export default App
