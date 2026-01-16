/**
 * Created by dudunato on 31/05/22.
 */

import cc_TokenizerURL from '@salesforce/label/c.cc_TokenizerURL'

export const cardTokenizerLabels = {
    cc_TokenizerURL
};

export const iframeCSS = encodeURIComponent(`
    html {
        margin: 0;
        padding: 0;
    }

    body {
        margin: 0;
        padding: 0;
    }
    
    form {
        padding-right: 20px;
    }
    
    input {
        font-family: monospace, monospace; 
        font-size: 13px;
        color: rgb(24, 24, 24);
        width: 100%;
        height: 30px;
        border: 1px solid #cccccc;
        border-radius: 0.25rem;
        line-height: 1.875rem;
        outline: 0;
        padding-left: 0.75rem;
    }
    
    input:active, input:focus {
        border-color: rgb(27, 150, 255);
        box-shadow: rgb(1, 118, 211) 0px 0px 3px 0px;
    }
    
    .error {
        border: 2px solid rgb(234, 0, 30)
    }
`.replace(/[\n|\t]/g, ''));