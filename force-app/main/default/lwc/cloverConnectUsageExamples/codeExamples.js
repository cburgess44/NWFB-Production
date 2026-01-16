/**
 * Created by dudunato on 15/06/22.
 */

export const simpleForm = `
    <c-clover-connect-payment-form 
        payment-type="card" // the options are: all (default), card, eCheck
        enable-comments="true"
    ></c-clover-connect-payment-form>
`;

export const formWithAllOptions = `
    <c-clover-connect-payment-form 
        enable-email-capture="true"
        enable-scheduling-plan="all" // you can set: "all", "monthly" or "yearly"
        enable-anonymous="true"
        enable-comments="true"
        user-fields={userFields} // user fields are any custom field you intend to store in clove connect
    ></c-clover-connect-payment-form>
`;

export const manageAccounts = `
    <c-clover-connect-profile-manager
        profile-id="15309722213283839773" // we're using this profile id as an example, please don't delete it on CloverConnect dashboard
    ></c-clover-connect-profile-manager>
    
    // in c-clover-connect-profile-manager we use c-clover-connect-payment-form as:
    <c-clover-connect-payment-form 
        profile-mode="true"
        profile-id="" // here you will pass the profile id in which the account will be added to
        onprofilesave={handleAccountSave}
        onprofilecancel={toggleAccountForm}
    ></c-clover-connect-payment-form>
`;

export const formWithSavedAccounts = `
    <c-clover-connect-payment-form 
        profile-id="15309722213283839773" // we're using this profile id as an example, please don't delete it on CloverConnect dashboard
        enable-anonymous="true"
        enable-comments="true"
        enable-save-for-future="true" // this won't work, once you have a profile you can't update it throw a new account being created from an authorized endpoint
    ></c-clover-connect-payment-form>
`;

export const lockedAmountForm = `
    <c-clover-connect-payment-form 
        payment-type="card"
        locked-amount="10" // pass any fixed amount here
    ></c-clover-connect-payment-form>
`;