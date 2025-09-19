import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.6/index.ts';
import { assertEquals } from 'https://deno.land/std@0.170.0/testing/asserts.ts';

Clarinet.test({
    name: "Move Asset Protocol - Asset Minting Validation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const block = chain.mineBlock([
            Tx.contractCall('move-asset-protocol', 'mint-digital-asset', [
                types.utf8('https://sample-metadata.uri'),
                types.utf8('Test Asset'),
                types.utf8('A test digital asset'),
                types.tuple({
                    width: types.uint(100),
                    height: types.uint(100),
                    depth: types.uint(100)
                }),
                types.list([types.utf8('Platform1'), types.utf8('Platform2')]),
                types.utf8('Creative'),
                types.utf8('GLB'),
                types.bool(true),
                types.uint(50)
            ], deployer.address)
        ]);

        assertEquals(block.receipts.length, 1);
        block.receipts[0].result.expectOk().expectUint(0);
    }
});

Clarinet.test({
    name: "Move Asset Protocol - Asset Transfer Validation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;

        const mintBlock = chain.mineBlock([
            Tx.contractCall('move-asset-protocol', 'mint-digital-asset', [
                types.utf8('https://sample-metadata.uri'),
                types.utf8('Test Asset'),
                types.utf8('A test digital asset'),
                types.tuple({
                    width: types.uint(100),
                    height: types.uint(100),
                    depth: types.uint(100)
                }),
                types.list([types.utf8('Platform1'), types.utf8('Platform2')]),
                types.utf8('Creative'),
                types.utf8('GLB'),
                types.bool(true),
                types.uint(50)
            ], deployer.address)
        ]);

        const transferBlock = chain.mineBlock([
            Tx.contractCall('move-asset-protocol', 'transfer-asset-ownership', [
                types.uint(0),
                types.principal(wallet1.address)
            ], deployer.address)
        ]);

        assertEquals(transferBlock.receipts.length, 1);
        transferBlock.receipts[0].result.expectOk().expectBool(true);
    }
});