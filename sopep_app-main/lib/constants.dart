// Copyright (c) 2023, StarIC, author: Justin Y. Kim

const String SOPEP_SERVICE_UUID = '9d0716f9-a4e0-44a8-a17e-5b3b3a176100';
const String SOPEP_CHARACTERISTIC_UUID = '9d0716f9-a4e0-44a8-a17e-5b3b3a176101';

const int CONN_ATTEMPTS_MAX = 3;
const int MTU_SIZE_MAX = 247;
const int BLE_ATT_HEADER_BYTES = 3;
const int BLE_CMD_ECHO_BYTES = 29; // Byte size of {'cmd': 'echo-test', 'data':}
