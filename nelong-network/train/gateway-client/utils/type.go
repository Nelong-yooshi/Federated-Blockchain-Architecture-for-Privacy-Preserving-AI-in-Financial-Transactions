package utils

import (
	"crypto/rsa"

	"github.com/hyperledger/fabric-gateway/pkg/client"
)

type TxnData struct {
	AcctNbrOri           string  `json:"acct_nbr_ori" csv:"acct_nbr_ori"`
	AcctNbr              string  `json:"acct_nbr" csv:"acct_nbr"`
	CustID               string  `json:"cust_id" csv:"cust_id"`
	ActDate              string  `json:"act_date" csv:"act_date"`
	TxDate               string  `json:"tx_date" csv:"tx_date"`
	TxTime               string  `json:"tx_time" csv:"tx_time"`
	Drcr                 int     `json:"drcr" csv:"drcr"`
	TxAmt                int     `json:"tx_amt" csv:"tx_amt"`
	PbBal                int     `json:"pb_bal" csv:"pb_bal"`
	TxBrh                int     `json:"tx_brh" csv:"tx_brh"`
	Cur                  string  `json:"cur" csv:"cur"`
	ChannelDesc          string  `json:"channel_desc" csv:"channel_desc"`
	Chal1                string  `json:"chal_1" csv:"chal_1"`
	TimeDiff             int     `json:"time_diff" csv:"time_diff"`
	DailyTotal1          int     `json:"daily_total_1" csv:"daily_total_1"`
	DailyTotal2          int     `json:"daily_total_2" csv:"daily_total_2"`
	DailyCnt1            int     `json:"daily_cnt_1" csv:"daily_cnt_1"`
	DailyCnt2            int     `json:"daily_cnt_2" csv:"daily_cnt_2"`
	AccumulatedCnt       int     `json:"accumulated_cnt" csv:"accumulated_cnt"`
	AcctCntrpartCnt      int     `json:"acct_cntrpart_cnt" csv:"acct_cntrpart_cnt"`
	DistinctCntrpartCnt  int     `json:"distinct_cntrpart_cnt" csv:"distinct_cntrpart_cnt"`
	TestTxn              int     `json:"test_txn" csv:"test_txn"`
	AmtDiff              int     `json:"amt_diff" csv:"amt_diff"`
	TxBrhCnt             int     `json:"tx_brh_cnt" csv:"tx_brh_cnt"`
	IncomeWithdrawRatio  float32 `json:"income_withdraw_ratio" csv:"income_withdraw_ratio"`
	ActionCnt            int     `json:"action_cnt" csv:"action_cnt"`
	SessionTotalAmt      int     `json:"session_total_amt" csv:"session_total_amt"`
	SessionAccumulatedAmt int    `json:"session_accumulated_amt" csv:"session_accumulated_amt"`
	Flow                 int     `json:"flow" csv:"flow"`
	FlowTotalAmt2        int     `json:"flow_total_amt_2" csv:"flow_total_amt_2"`
	FlowTxAmtRatio       float32 `json:"flow_tx_amt_ratio" csv:"flow_tx_amt_ratio"`
	FlowTxAmtSeq         int     `json:"flow_tx_amt_seq" csv:"flow_tx_amt_seq"`
	FlowTxAmtSeqRatio    float32 `json:"flow_tx_amt_seq_ratio" csv:"flow_tx_amt_seq_ratio"`
	FlowTtlAmt1          int     `json:"flow_ttl_amt_1" csv:"flow_ttl_amt_1"`
	FlowTtlAmtDrcrRatio  float32 `json:"flow_ttl_amt_drcr_ratio" csv:"flow_ttl_amt_drcr_ratio"`
	FlowAvgTimeDiff      int     `json:"flow_avg_time_diff" csv:"flow_avg_time_diff"`
	ActiveDays           int     `json:"active_days" csv:"active_days"`
	AcctAcnoInNum        int     `json:"acct_acno_in_num" csv:"acct_acno_in_num"`
	AcctBankNo           string  `json:"acct_bank_no" csv:"acct_bank_no"`
	UserIDLevel          int     `json:"user_id_level" csv:"user_id_level"`
	ReqLstDay            int     `json:"req_lst_day" csv:"req_lst_day"`
	OriReqBrhNum         int     `json:"ori_req_brh_num" csv:"ori_req_brh_num"`
	Hour                 int     `json:"hour" csv:"hour"`
	SmallBal             int     `json:"small_bal" csv:"small_bal"`
	EbCheck              int     `json:"eb_check" csv:"eb_check"`
	MbCheck              int     `json:"mb_check" csv:"mb_check"`
	MbLimit              int     `json:"mb_limit" csv:"mb_limit"`
	ChgDeviceCnt         int     `json:"chg_device_cnt" csv:"chg_device_cnt"`
	ChgIPCnt             int     `json:"chg_ip_cnt" csv:"chg_ip_cnt"`
	Label                int     `json:"label" csv:"label"`
	DailyTxnDiff         int     `json:"daily_txn_diff" csv:"daily_txn_diff"`
	TxRatio              float32 `json:"tx_ratio" csv:"tx_ratio"`
}

type AcctData struct {
	AcctNbrOri                 string  `json:"acct_nbr_ori" csv:"acct_nbr_ori"`
	CustID                     string  `json:"cust_id" csv:"cust_id"`
	Age                        int     `json:"age" csv:"age"`
	Occupation                 int     `json:"occupation" csv:"occupation"`
	LostFlg                    int     `json:"lost_flg" csv:"lost_flg"`
	ChopStatus                 int     `json:"chop_status" csv:"chop_status"`
	DormantActRatio            float32 `json:"dormant_act_ratio" csv:"dormant_act_ratio"`
	CfpebtrfinCnt              int     `json:"cfpebtrfin_cnt" csv:"cfpebtrfin_cnt"`
	TtlTransCrdt               int     `json:"ttl_trans_crdt" csv:"ttl_trans_crdt"`
	DailyTransCrdt             float32 `json:"daily_trans_crdt" csv:"daily_trans_crdt"`
	DailyMaxCrdt               float32 `json:"daily_max_crdt" csv:"daily_max_crdt"`
	TtlMbCrdt                  int     `json:"ttl_mb_crdt" csv:"ttl_mb_crdt"`
	DailyMbCnt                 int     `json:"daily_mb_cnt" csv:"daily_mb_cnt"`
	DailyMaxMbCrdt             float32 `json:"daily_max_mb_crdt" csv:"daily_max_mb_crdt"`
	ATMLarge                   int     `json:"atm_large" csv:"atm_large"`
	WindSumTransDiff           float32 `json:"wind_sum_trans_diff" csv:"wind_sum_trans_diff"`
	WindCntTransDiff           int     `json:"wind_cnt_trans_diff" csv:"wind_cnt_trans_diff"`
	AvgTxAmt                   float32 `json:"avg_tx_amt" csv:"avg_tx_amt"`
	TxnAumRatio                float32 `json:"txnaum_ratio" csv:"txnaum_ratio"`
	AcctNoSav                  int     `json:"acct_no_sav" csv:"acct_no_sav"`
	SwindleFlag                int     `json:"swindle_flag" csv:"swindle_flag"`
	Aw27                       int     `json:"aw27" csv:"aw27"`
	CommonSuspiciousAcctCnt    int     `json:"common_suspicious_acct_cnt" csv:"common_suspicious_acct_cnt"`
	ZeroRatio                  float32 `json:"0_ratio" csv:"0_ratio"`
	OneRatio                   float32 `json:"1_ratio" csv:"1_ratio"`
	TwoRatio                   float32 `json:"2_ratio" csv:"2_ratio"`
	ThreeRatio                 float32 `json:"3_ratio" csv:"3_ratio"`
	FourRatio                  float32 `json:"4_ratio" csv:"4_ratio"`
	Time850Ratio               float32 `json:"time_850_ratio" csv:"time_850_ratio"`
	Time1700Ratio              float32 `json:"time_1700_ratio" csv:"time_1700_ratio"`
	Time3400Ratio              float32 `json:"time_3400_ratio" csv:"time_3400_ratio"`
	Time5100Ratio              float32 `json:"time_5100_ratio" csv:"time_5100_ratio"`
	Time6800Ratio              float32 `json:"time_6800_ratio" csv:"time_6800_ratio"`
	TimeLargeRatio             float32 `json:"time_large_ratio" csv:"time_large_ratio"`
	DailyTxnDiff               int     `json:"daily_txn_diff" csv:"daily_txn_diff"`
	TxnDiff0                   int     `json:"txn_diff_0" csv:"txn_diff_0"`
	TxnDiff3000                int     `json:"txn_diff_3000" csv:"txn_diff_3000"`
	TxnDiff5000                int     `json:"txn_diff_5000" csv:"txn_diff_5000"`
	TxnDiff10000               int     `json:"txn_diff_10000" csv:"txn_diff_10000"`
	TxnDiff20000               int     `json:"txn_diff_20000" csv:"txn_diff_20000"`
	TxnDiffLarge               int     `json:"txn_diff_large" csv:"txn_diff_large"`
	TestTxn                    int     `json:"test_txn" csv:"test_txn"`
	Drcr1                      int     `json:"drcr_1" csv:"drcr_1"`
	Drcr2                      int     `json:"drcr_2" csv:"drcr_2"`
	AcctCntrpartCnt            int     `json:"acct_cntrpart_cnt" csv:"acct_cntrpart_cnt"`
	EveOnlineTimes             int     `json:"eve_online_times" csv:"eve_online_times"`
	EveTimes                   int     `json:"eve_times" csv:"eve_times"`
	TimeDiff                   int     `json:"time_diff" csv:"time_diff"`
	Dr1Count                   int     `json:"dr1_count" csv:"dr1_count"`
	Dr1ShortCount              int     `json:"dr1_short_count" csv:"dr1_short_count"`
	ShortTimePercent           float32 `json:"short_time_percent" csv:"short_time_percent"`
	FlowTtlAmt1                int     `json:"flow_ttl_amt_1" csv:"flow_ttl_amt_1"`
	FlowAvgTimeDiff            int     `json:"flow_avg_time_diff" csv:"flow_avg_time_diff"`
	TxBrhCnt                   int     `json:"tx_brh_cnt" csv:"tx_brh_cnt"`
	ActiveDays                 int     `json:"active_days" csv:"active_days"`
	AumAmt                     float32 `json:"aum_amt" csv:"aum_amt"`
	RmFlg                      int     `json:"rm_flg" csv:"rm_flg"`
	CaActMajorCardCount        int     `json:"ca_act_major_card_count" csv:"ca_act_major_card_count"`
	ChgDeviceCnt               int     `json:"chg_device_cnt" csv:"chg_device_cnt"`
	ChgIPCnt                   int     `json:"chg_ip_cnt" csv:"chg_ip_cnt"`
	PbBalFlg                   int     `json:"pb_bal_flg" csv:"pb_bal_flg"`
	MaxCheck                   int     `json:"max_check" csv:"max_check"`
	ForFlag                    int     `json:"for_flag" csv:"for_flag"`
	Label                      int     `json:"label" csv:"label"`	
}

type TrainData struct {
	TxnData TxnData    `json:"txn_data"`
	AcctData AcctData  `json:"acct_data"`
}

type TrainDataID struct {
	TxnDataID  string
	AcctDataID string
}

// 存enclave-server回傳的attestation
type AttestationResponse struct {
	Document struct {
		Pubkey string `json:"public_key"`
		ModelHash string `json:"model_hash"`
		EnclaveConfig string `json:"enclave_config"`
	} `json:"document"`
	Signature string `json:"signature"`
}

// 資料加密後回傳架構
type EncryptedPayload struct {
	Key   string  `json:"key"`    // base64 encoded encrypted AES key
	Nonce string  `json:"nonce"`  // baase64 nonce
	Data  string  `json:"data"`   // base64 encrypted content
}

// 存API的上下文
type AppContext struct {
	Contract     *client.Contract
	Attestation  *AttestationResponse
	Pubkey 	     *rsa.PublicKey
	SessionNbr   *string
}