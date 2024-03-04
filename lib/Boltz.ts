import ERC20ABI from '../out/ERC20.sol/ERC20.json';
import ERC20SwapABI from '../out/ERC20Swap.sol/ERC20Swap.json';
import EtherSwapABI from '../out/EtherSwap.sol/EtherSwap.json';
import { targetFee } from './TargetFee';
import { OutputType } from './consts/Enums';
import Networks from './consts/Networks';
import * as Types from './consts/Types';
import {
  ClaimDetails,
  RefundDetails,
  ScriptElement,
  TransactionOutput,
} from './consts/Types';
import { init } from './init';
import { constructClaimTransaction } from './liquid/swap/Claim';
import { constructRefundTransaction } from './liquid/swap/Refund';
import reverseSwapTree from './liquid/swap/ReverseSwapTree';
import Musig from './musig/Musig';
import { detectPreimage } from './swap/PreimageDetector';
import reverseSwapScript from './swap/ReverseSwapScript';
import {
  extractClaimPublicKeyFromReverseSwapTree,
  extractRefundPublicKeyFromReverseSwapTree,
} from './swap/ReverseSwapTree';
import * as Scripts from './swap/Scripts';
import { detectSwap } from './swap/SwapDetector';
import swapScript from './swap/SwapScript';
import swapTree, {
  extractClaimPublicKeyFromSwapTree,
  extractRefundPublicKeyFromSwapTree,
} from './swap/SwapTree';
import * as SwapTreeSerializer from './swap/SwapTreeSerializer';
import * as SwapUtils from './swap/SwapUtils';
import * as TaprootUtils from './swap/TaprootUtils';

const ContractABIs = {
  ERC20: ERC20ABI.abi,
  EtherSwap: EtherSwapABI.abi,
  ERC20Swap: ERC20SwapABI.abi,
};

export {
  Musig,
  Types,
  Networks,
  OutputType,
  ContractABIs,
  ClaimDetails,
  ScriptElement,
  RefundDetails,
  TransactionOutput,
  Scripts,
  SwapUtils,
  TaprootUtils,
  SwapTreeSerializer,
  init,
  swapTree,
  targetFee,
  swapScript,
  detectSwap,
  detectPreimage,
  reverseSwapTree,
  reverseSwapScript,
  constructClaimTransaction,
  constructRefundTransaction,
  extractClaimPublicKeyFromSwapTree,
  extractRefundPublicKeyFromSwapTree,
  extractClaimPublicKeyFromReverseSwapTree,
  extractRefundPublicKeyFromReverseSwapTree,
};
