import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test batch file registration",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const testHashes = [
            '0x1234567890123456789012345678901234567890123456789012345678901234',
            '0x2234567890123456789012345678901234567890123456789012345678901234'
        ];
        const descriptions = ["Test Doc 1", "Test Doc 2"];
        
        let block = chain.mineBlock([
            Tx.contractCall('file-notary', 'register-batch', [
                types.list(testHashes.map(h => types.buff(h))),
                types.list(descriptions.map(d => types.ascii(d))),
                types.ascii("Test Batch")
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
    },
});

Clarinet.test({
    name: "Test batch verification",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        const testHashes = [
            '0x1234567890123456789012345678901234567890123456789012345678901234',
            '0x2234567890123456789012345678901234567890123456789012345678901234'
        ];
        const descriptions = ["Test Doc 1", "Test Doc 2"];
        
        let block = chain.mineBlock([
            Tx.contractCall('file-notary', 'register-batch', [
                types.list(testHashes.map(h => types.buff(h))),
                types.list(descriptions.map(d => types.ascii(d))),
                types.ascii("Test Batch")
            ], wallet1.address),
            Tx.contractCall('file-notary', 'verify-batch', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectOk();
    },
});
