import zkp from '@michael1011/secp256k1-zkp';
import { confidential, Transaction } from 'liquidjs-lib';
import { getHexBuffer } from '../../../lib/Utils';
import { targetFee } from '../../../lib/TargetFee';
import { liquidClaimDetails } from './swap/ClaimDetails';
import { constructClaimTransaction, init } from '../../../lib/liquid';

describe('Liquid TargetFee', () => {
  beforeAll(async () => {
    init(await zkp());
  });

  test.each([0.1, 0.2, 1, 3, 12, 42, 32, 123])(
    'should target fees @ %p sat/vbyte',
    (satPerVbyte: number) => {
      const utxo = {
        ...liquidClaimDetails[0],
        value: confidential.satoshiToConfidentialValue(10 ** 8),
      };
      const tx = targetFee<Transaction>(satPerVbyte, (fee) =>
        constructClaimTransaction(
          [utxo],
          getHexBuffer('00140000000000000000000000000000000000000000'),
          fee,
          false,
        ),
      );

      expect(tx instanceof Transaction).toBeTruthy();

      expect(tx.outs).toHaveLength(2);
      expect(confidential.confidentialValueToSatoshi(tx.outs[0].value)).toEqual(
        confidential.confidentialValueToSatoshi(utxo.value) -
          Math.ceil((tx.virtualSize() + 1) * satPerVbyte),
      );
    },
  );
});
