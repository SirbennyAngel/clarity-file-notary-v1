import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test file registration",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        const testHash = '0x1234567890123456789012345678901234567890123456789012345678901234';
        
        let block = chain.mineBlock([
            Tx.contractCall('file-notary', 'register-file', [
                types.buff(testHash),
                types.ascii("Test Document")
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
    },
});

Clarinet.test({
    name: "Test file verification by owner",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const testHash = '0x1234567890123456789012345678901234567890123456789012345678901234';
        
        let block = chain.mineBlock([
            Tx.contractCall('file-notary', 'verify-file', [
                types.buff(testHash)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk();
    },
});

Clarinet.test({
    name: "Test ownership transfer",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        const testHash = '0x1234567890123456789012345678901234567890123456789012345678901234';
        
        let block = chain.mineBlock([
            Tx.contractCall('file-notary', 'register-file', [
                types.buff(testHash),
                types.ascii("Test Document")
            ], wallet1.address),
            Tx.contractCall('file-notary', 'transfer-ownership', [
                types.buff(testHash),
                types.principal(wallet2.address)
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectOk();
    },
});
