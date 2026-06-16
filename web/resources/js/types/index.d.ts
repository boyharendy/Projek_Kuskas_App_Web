export interface User {
    id: string | number;
    name: string;
    email: string;
    email_verified_at?: string;
    avatar_url?: string;
}

export type PageProps<
    T extends Record<string, unknown> = Record<string, unknown>,
> = T & {
    auth: {
        user: User;
    };
};
