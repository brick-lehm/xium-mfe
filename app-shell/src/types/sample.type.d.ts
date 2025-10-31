/// <reference types="react" />

declare module 'sample/Sample' {
    export interface SampleProps {
        title?: string;
    }

    const RecurringBillingForm: React.ComponentType<SampleProps>;
    export default RecurringBillingForm;
}
