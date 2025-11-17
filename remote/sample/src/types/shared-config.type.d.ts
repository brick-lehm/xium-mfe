export type SharedConfigExtended = {
    singleton?: boolean;
    requiredVersion?: string | false;
    version?: string | false;
    eager?: boolean;
    import?: boolean;
    shareScope?: string;
    packagePath?: string;
    generate?: boolean;
    modulePreload?: boolean;
};
