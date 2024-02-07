// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

interface INamed {
  function nameId() external view returns (bytes4);
}
