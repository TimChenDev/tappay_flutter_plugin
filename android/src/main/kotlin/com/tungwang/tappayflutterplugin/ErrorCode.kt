package com.tungwang.tappayflutterplugin

/**
 * 整理了 flutter result 可能會用到的 Error Code
 */
object ErrorCode {

    /**
     * 找不到對應的 method
     */
    const val NO_MATCHED_METHOD = "0001"

    /**
     * 完全沒有變數
     */
    const val NO_ARGUMENTS = "0002"

    /**
     * 缺少某個必須的變數
     */
    const val MISSING_ARGUMENTS = "0003"

    // 針對各種錯誤狀況制定 ErrorCode
    const val CONTEXT_IS_NULL = "1001"
    const val SETUP_TAPPAY_ERROR = "1002"
    const val IS_CARD_VALID = "1003"
    const val USER_CANCELED = "1004"

    // 針對支付功能不可用時的 ErrorCode
    const val EASY_WALLET_UNAVAILABLE = "2001"
    const val LINE_PAY_UNAVAILABLE = "2002"
    const val GOOGLE_PAY_UNAVAILABLE = "2003"

    // 針對 getPrime 失敗的 ErrorCode
    const val GET_PRIME_FAILED = "3000"
    const val GET_EASY_WALLET_PRIME_FAILED = "3001"
    const val GET_LINE_PAY_PRIME_FAILED = "3002"
    const val GET_GOOGLE_PAY_PRIME_FAILED = "3003"
}