package com.nikonhacker.realos;

import com.nikonhacker.Format;

public class MailboxInformation extends RealOsObject {

    private int waitTaskInformation;
    private int pkMsg;

    public MailboxInformation(int objectId, ErrorCode errorCode, int extendedInformation, int waitTaskInformation, int pkMsg) {
        super(objectId, errorCode, extendedInformation);
        this.waitTaskInformation = waitTaskInformation;
        this.pkMsg = pkMsg;
    }

    public int getWaitTaskInformation() {
        return waitTaskInformation;
    }

    public int getPkMsg() {
        return pkMsg;
    }

    @Override
    public String toString() {
        if (getErrorCode() != ErrorCode.E_OK) {
            return getErrorCode().toString();
        }
        return "Mailbox 0x" + Format.asHex(objectId, 2) + ": pk_msg=0x" + Format.asHex(pkMsg, 8) + ", " + ((waitTaskInformation==0)?"no waiting task":"first waiting task=0x" + Format.asHex(waitTaskInformation, 2)) + ", extendedInformation=0x" + Format.asHex(getExtendedInformation(), 8);
    }
}
