package utils

import (
	"crypto/rsa"
	"sync"
	"github.com/hyperledger/fabric-gateway/pkg/client"
)

type TxnData struct {
    AcctNbrOri            string  `json:"acct_nbr_ori"`
    AcctNbr               string  `json:"acct_nbr"`
    CustID                string  `json:"cust_id"`
    ActDate               string  `json:"act_date"`
    TxDate                string  `json:"tx_date"`
    TxTime                string  `json:"tx_time"`
    Drcr                  int     `json:"drcr"`
    TxAmt                 float32     `json:"tx_amt"`
    PbBal                 float32     `json:"pb_bal"`
    TxBrh                 float32     `json:"tx_brh"`
    Cur                   string  `json:"cur"`
    ChannelDesc           string  `json:"channel_desc"`
    Chal1                 string  `json:"chal_1"`
    TimeDiff              float32     `json:"time_diff"`
    DailyTotal1           float32     `json:"daily_total_1"`
    DailyTotal2           float32    `json:"daily_total_2"`
    DailyCnt1             float32     `json:"daily_cnt_1"`
    DailyCnt2             float32     `json:"daily_cnt_2"`
    AccumulatedCnt        float32     `json:"accumulated_cnt"`
    AcctCntrpartCnt       float32     `json:"acct_cntrpart_cnt"`
    DistinctCntrpartCnt   float32    `json:"distinct_cntrpart_cnt"`
    TestTxn               float32     `json:"test_txn"`
    AmtDiff               float64 `json:"amt_diff"`
    TxBrhCnt             float32     `json:"tx_brh_cnt"`
    IncomeWithdrawRatio   float64 `json:"income_withdraw_ratio"`
    ActionCnt             float32     `json:"action_cnt"`
    SessionTotalAmt       float32     `json:"session_total_amt"`
    SessionAccumulatedAmt float32     `json:"session_accumulated_amt"`
    Flow                 float32     `json:"flow"`
    FlowTotalAmt2         float32     `json:"flow_total_amt_2"`
    FlowTxAmtRatio        float64 `json:"flow_tx_amt_ratio"`
    FlowTxAmtSeq          float32    `json:"flow_tx_amt_seq"`
    FlowTxAmtSeqRatio     float64 `json:"flow_tx_amt_seq_ratio"`
    FlowTtlAmt1         float32    `json:"flow_ttl_amt_1"`
    FlowTtlAmtDrcrRatio   float64 `json:"flow_ttl_amt_drcr_ratio"`
    FlowAvgTimeDiff       float64 `json:"flow_avg_time_diff"`
    ActiveDays           float32    `json:"active_days"`
    AcctAcnoInNum         float32     `json:"acct_acno_in_num"`
    AcctBankNo            float32     `json:"acct_bank_no"`
    UserIDLevel           float32     `json:"user_id_level"`
    ReqLstDay             float32     `json:"req_lst_day"`
    OriReqBrhNum          float32     `json:"ori_req_brh_num"`
    Hour                  float32     `json:"hour"`
    SmallBal              float32     `json:"small_bal"`
    EbCheck               float32     `json:"eb_check"`
    MbCheck               float32     `json:"mb_check"`
    MbLimit               float32     `json:"mb_limit"`
    ChgDeviceCnt          float32     `json:"chg_device_cnt"`
    ChgIPCnt              float32     `json:"chg_ip_cnt"`
    Label                 float32     `json:"label"`
    DailyTxnDiff          float32     `json:"daily_txn_diff"`
    TxRatio               float64 `json:"tx_ratio"`
}

type TrainData struct {
    TxnData []TxnData `json:"txnData"`
}



// 存enclave-server回傳的attestation
type AttestationResponse struct {
	Type string `json:"type"`
	Document struct {
		Pubkey string `json:"public_key"`
		ModelHash string `json:"model_hash"`
		EnclaveConfig string `json:"enclave_config"`
	} `json:"document"`
	Signature string `json:"signature"`
}

// 資料加密後回傳架構
type EncryptedPayload struct {
	Type  string  `json:"type"`
	Key   string  `json:"key"`    // base64 encoded encrypted AES key
	Nonce string  `json:"nonce"`  // baase64 nonce
	Data  string  `json:"data"`   // base64 encrypted content
	Tag   string `json:"tag"`
}

// 存API的上下文
type AppContext struct {
	IsTraining    bool
	Contract      *client.Contract
	Attestation   *AttestationResponse
	Pubkey 	      *rsa.PublicKey
	SessionNbr    *string
	SessionMember *[]string    `json:"memberList"`
	Mu 			  sync.Mutex
}