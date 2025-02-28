import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous test cases remain the same]

Clarinet.test({
    name: "Test contract pause functionality",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        const testHash = '0x1234567890123456789012345678901234567890123456789012345678901234';
        
        let block = chain.mineBlock([
            Tx.contractCall('file-notary', 'toggle-contract-pause', [], deployer.address),
            Tx.contractCall('file-notary', 'register-file', [
                types.buff(testHash),
                types.ascii("Test Document")
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectErr(105); // err-contract-paused
    },
});

Clarinet.test({
    name: "Test empty input validation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const testHash = '0x1234567890123456789012345678901234567890123456789012345678901234';
        
        let block = chain.mineBlock([
            Tx.contractCall('file-notary', 'register-file', [
                types.buff(testHash),
                types.ascii("")
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectErr(104); // err-empty-input
    },
});
