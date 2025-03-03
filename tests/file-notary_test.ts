import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous test cases remain]

Clarinet.test({
    name: "Test rate limiting functionality",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const testHash = '0x1234567890123456789012345678901234567890123456789012345678901234';
        
        let blocks = [];
        for (let i = 0; i < 11; i++) {
            blocks.push(
                Tx.contractCall('file-notary', 'register-file', [
                    types.buff(testHash + i),
                    types.ascii("Test Document")
                ], wallet1.address)
            );
        }
        
        let block = chain.mineBlock(blocks);
        block.receipts[10].result.expectErr(106); // err-rate-limit
    },
});

Clarinet.test({
    name: "Test file history tracking",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const testHash = '0x1234567890123456789012345678901234567890123456789012345678901234';
        
        let block = chain.mineBlock([
            Tx.contractCall('file-notary', 'register-file', [
                types.buff(testHash),
                types.ascii("Test Document")
            ], wallet1.address),
            Tx.contractCall('file-notary', 'get-file-history', [
                types.buff(testHash)
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectOk();
    },
});

// [Additional test cases for new functionality]
