// 本当はリモート側で .d.ts ファイルを生成してホストアプリに配布？
// 今回はホストアプリ側で定義している

declare module 'sample/Sample' {

    export interface SampleProps {
        title: string;
    }

    const Sample: React.FC<SampleProps>
    export {Sample}
}
