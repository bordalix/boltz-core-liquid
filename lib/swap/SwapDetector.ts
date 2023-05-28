/**
 * This file is based on the repository github.com/submarineswaps/swaps-service created by Alex Bosworth
 */

import { Transaction, TxOutput } from 'bitcoinjs-lib';
import { OutputType } from '../consts/Enums';
import { p2shOutput, p2shP2wshOutput, p2wshOutput } from './Scripts';

type LiquidTxOutput = Omit<TxOutput, 'value'> & {
  value: Buffer;
  asset: Buffer;
  nonce: Buffer;
  rangeProof?: Buffer;
  surjectionProof?: Buffer;
};

type DetectedSwap<T> = {
  type: OutputType;
  vout: number;
} & (T extends Transaction ? TxOutput : LiquidTxOutput);

/**
 * Detects a swap output with the matching redeem script in a transaction
 */
export const detectSwap = <
  T extends { outs: (TxOutput | LiquidTxOutput)[] } = Transaction,
>(
  redeemScript: Buffer,
  transaction: T,
): DetectedSwap<T> | undefined => {
  const scripts: [OutputType, Buffer][] = [
    [OutputType.Legacy, p2shOutput(redeemScript)],
    [OutputType.Compatibility, p2shP2wshOutput(redeemScript)],
    [OutputType.Bech32, p2wshOutput(redeemScript)],
  ];

  for (const [vout, output] of transaction.outs.entries()) {
    const scriptMatch = scripts.find(([, script]) =>
      script.equals(output.script),
    );

    if (scriptMatch) {
      return {
        vout,
        type: scriptMatch[0],
        ...output,
      } as DetectedSwap<T>;
    }
  }

  return;
};
