export type SandboxMode = "strict" | "interactive" | "permissive";
export type AccessMode = "read" | "write";

export interface SandboxConfig {
  enabled?: boolean;
  mode?: SandboxMode;
  network?: {
    block?: boolean;
  };
  filesystem?: {
    allowRead?: string[];
    allowWrite?: string[];
    allowReadWrite?: string[];
    denyRead?: string[];
    denyWrite?: string[];
  };
}

export interface RuntimeConfigExtras {
  ignoreViolations?: Record<string, string[]>;
  enableWeakerNestedSandbox?: boolean;
  enableWeakerNetworkIsolation?: boolean;
  allowPty?: boolean;
}

export interface EffectivePaths {
  readWrite: string[];
  read: string[];
  write: string[];
  missing: {
    readWrite: string[];
    read: string[];
    write: string[];
  };
}

export type ConfigScope = "global" | "project";

export interface ExecResult {
  exitCode: number | null;
  output: string;
}
