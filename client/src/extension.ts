import * as vscode from 'vscode'
import { LeanToyDebugAdapter } from './adapter'

class LeanToyDebugAdapterFactory implements vscode.DebugAdapterDescriptorFactory {
    constructor(private readonly output: vscode.OutputChannel) {}

    createDebugAdapterDescriptor(_session: vscode.DebugSession): vscode.ProviderResult<vscode.DebugAdapterDescriptor> {
        const adapter = new LeanToyDebugAdapter(this.output)
        return new vscode.DebugAdapterInlineImplementation(adapter)
    }
}

class LeanToyDebugConfigurationProvider implements vscode.DebugConfigurationProvider {
    resolveDebugConfiguration(
        _folder: vscode.WorkspaceFolder | undefined,
        config: vscode.DebugConfiguration,
    ): vscode.ProviderResult<vscode.DebugConfiguration> {
        if (!config.type) {
            config.type = 'lean-toy-dap'
        }
        if (!config.request) {
            config.request = 'launch'
        }
        if (!config.name) {
            config.name = 'Lean Toy DAP'
        }
        if (!config.source) {
            const active = vscode.window.activeTextEditor?.document.uri
            if (active?.scheme === 'file') {
                config.source = active.fsPath
            }
        }
        return config
    }
}

export function activate(context: vscode.ExtensionContext): void {
    const output = vscode.window.createOutputChannel('Lean Toy DAP')

    const configProvider = new LeanToyDebugConfigurationProvider()
    const adapterFactory = new LeanToyDebugAdapterFactory(output)

    context.subscriptions.push(
        output,
        vscode.debug.registerDebugConfigurationProvider('lean-toy-dap', configProvider),
        vscode.debug.registerDebugAdapterDescriptorFactory('lean-toy-dap', adapterFactory),
        vscode.commands.registerCommand('leanToyDap.startDebugging', async () => {
            const active = vscode.window.activeTextEditor?.document.uri
            const source = active?.scheme === 'file' ? active.fsPath : undefined
            await vscode.debug.startDebugging(undefined, {
                name: 'Lean Toy DAP',
                type: 'lean-toy-dap',
                request: 'launch',
                source,
                stopOnEntry: true,
            })
        }),
    )
}

export function deactivate(): void {}
