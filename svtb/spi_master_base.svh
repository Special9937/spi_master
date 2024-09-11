`ifndef __spi_master_base__
`define __spi_master_base__
// Enumerate
typedef enum { DEFAULT = 0,BOLD, DARK, ITALIC, UNDERLINE, REVERSE = 7,
               BLACK = 30, RED, GREEN, BROWN, BLUE, PURPLE, CYAN, GRAY, YELLOW } color_t;

typedef enum { LEFT, CENTER, RIGHT } pos_t;

typedef enum { ALL, DEBUG, INFO, DONE, PASS, WARN, ERROR, FAIL, FAULT, NONE } log_t;
class spi_master_base #(
    parameter            SYS_FREQ = 100_000_000,
    parameter            SCK_FREQ = 25_000_000 
);
    // Name
    string          name;

    // Print buffer
    string          buffer;
    bit             empty;

    // Logger
    log_t           level;
    int             log_fd;

    string          t_brk;

    int             w_cycle;
    int             w_label;
    int             w_name;
    int             w_msg;

    // User interface
    virtual spi_master_io intf;

    function new(virtual spi_master_io intf, string name = "spi_master", log_t level = ALL, int log_fd = 0);
        this.name     = name;
        this.level    = level;
        this.log_fd   = 0;  // ZERO == PRINT

        this.buffer   = "";
        this.empty    = 1;

        // Format Logger Width
        this.w_cycle  = 12;
        this.w_label  = 8;
        this.w_name   = 10;
        this.w_msg    = 64;

        this.t_brk   = " | ";

        // User Interface
        this.intf    = intf;
    endfunction  // new

    // Style Code
    extern function string getStyle(color_t color = DEFAULT);

    // Format Function
    extern function string fmtStyle(string _msg = "", color_t color = DEFAULT);
    extern function string fmtAlign(string _msg = "", pos_t _pos = LEFT, int width = _msg.len());
    extern function string fmtRepeat(string _msg = "", int count, string _brk = "");


    // Pretty Print Buffer Control
    extern function putStyle(color_t color = DEFAULT);
    extern function putString(string _msg = "");

    // Buffer Pop
    extern function string popString();
    extern function string getString();

    // Print Function
    extern function flush();
    extern function print(string _msg = "");

    extern function basicConfig(string filename = "dummy.log", log_t level = WARN);
    extern function tableConfig(int w_cycle = 12, int w_label = 8, int w_name = 10, int w_msg = 64);

    extern function string fmtTime();
    extern function string fmtLevel(log_t _level = INFO);
    extern function string fmtName();
    extern function string fmtLog(log_t _level = INFO, string _msg = "");

    extern function printLog(log_t _level = INFO, string _msg = "");
    extern function printDiv();
    extern function printTag();
    extern function printTop(string _msg = "");
    extern function printMsg(string _msg = "");

    // LOG LEVEL PRINTER
    extern function debug(string _str);
    extern function info(string _str);
    extern function done(string _str);
    extern function pass(string _str);
    extern function warn(string _str);
    extern function error(string _str);
    extern function fail(string _str);
    extern function fault(string _str);

    // Macro default tasks
    extern task watchdog(int _cycle = 1); // Watchdog timer
    extern task waitrun(int _cycle = 1);     // Wait _cycle clock
    extern task init(int _cycle = 1);     // Initialize all signal zero
    extern task reset(int _cycle = 4);    // Reset Internal core

    // User interface tasks
    extern task set_miso_i(bit  _miso_i = 0, int _log = 1);
    extern task dbg_mosi_o();
    extern task dbg_sck_o();
    extern task dbg_cs_n_o();
    extern task set_tx_byte_i(bit [7:0] _tx_byte_i = 0, int _log = 1);
    extern task set_tx_byte_valid_i(bit  _tx_byte_valid_i = 0, int _log = 1);
    extern task dbg_ready_o();
    extern task dbg_rx_byte_o();
    extern task dbg_rx_byte_valid_o();

    // User interface function
    function bit  get_mosi_o(int _log = 1);
        if(_log) begin
            this.info($sformatf(" * GET mosi_o                : %0d", intf.mosi_o));
        end
        return intf.mosi_o;
    endfunction
    function bit  get_sck_o(int _log = 1);
        if(_log) begin
            this.info($sformatf(" * GET sck_o                 : %0d", intf.sck_o));
        end
        return intf.sck_o;
    endfunction
    function bit  get_cs_n_o(int _log = 1);
        if(_log) begin
            this.info($sformatf(" * GET cs_n_o                : %0d", intf.cs_n_o));
        end
        return intf.cs_n_o;
    endfunction
    function bit  get_ready_o(int _log = 1);
        if(_log) begin
            this.info($sformatf(" * GET ready_o               : %0d", intf.ready_o));
        end
        return intf.ready_o;
    endfunction
    function bit [7:0] get_rx_byte_o(int _log = 1);
        if(_log) begin
            this.info($sformatf(" * GET rx_byte_o             : 0x%x (%0d)", intf.rx_byte_o, intf.rx_byte_o));
        end
        return intf.rx_byte_o;
    endfunction
    function bit  get_rx_byte_valid_o(int _log = 1);
        if(_log) begin
            this.info($sformatf(" * GET rx_byte_valid_o       : %0d", intf.rx_byte_valid_o));
        end
        return intf.rx_byte_valid_o;
    endfunction

endclass  // spi_master_base

//-----------------------------------------------------------------------------
// Title       : Format
// Description :
//-----------------------------------------------------------------------------
function string spi_master_base::fmtStyle(string _msg = "", color_t color = DEFAULT);
    if (color == YELLOW) begin
        return $sformatf("\033[1;33m%s\033[0;0m", _msg);
    end else begin
        return $sformatf("\033[0;%0dm%s\033[0;0m", color, _msg);
    end
endfunction  // fmtStyle

function string spi_master_base::fmtAlign(string _msg = "", pos_t _pos = LEFT, int width = _msg.len());
    int    mlen;
    string lpad;
    string rpad;

    mlen = _msg.len();

    if (mlen >= width) begin
        lpad = "";
        rpad = "";
    end else if (_pos == CENTER) begin
        mlen = width - mlen;
        lpad = this.fmtRepeat(" ", mlen / 2);
        rpad = this.fmtRepeat(" ", (mlen / 2) + (mlen % 2));
    end else if (_pos == RIGHT) begin
        mlen = width - mlen;
        lpad = this.fmtRepeat(" ", mlen);
        rpad = "";
    end else begin
        mlen = width - mlen;
        lpad = "";
        rpad = this.fmtRepeat(" ", mlen);
    end

    return $sformatf("%s%s%s", lpad, _msg, rpad);

endfunction  // print


function string spi_master_base::fmtRepeat(string _msg = "", int count, string _brk = "");
    string _str = "";

    for (int i = 0; i < count; i++) begin
        _str = $sformatf("%s%s%s", _str, _brk, _msg);
    end

    return _str;

endfunction  // fmtRepeat

//-----------------------------------------------------------------------------
// Title       : Pretty Print Buffer Control
// Description :
//-----------------------------------------------------------------------------
function spi_master_base::putStyle(color_t color = DEFAULT);
    this.putString(this.getStyle(color));
endfunction  // putStyle

function spi_master_base::putString(string _msg = "");
    if (this.empty) begin
        this.empty  = 0;
        this.buffer = _msg;
    end else begin
        this.buffer = $sformatf("%s%s", this.buffer, _msg);
    end
endfunction  // putString

function string spi_master_base::getStyle(color_t color = DEFAULT);
    if (color == YELLOW) return "\033[1;33m";
    else return $sformatf("\033[0;%0dm", color);
endfunction  // getStyle

function string spi_master_base::getString();
    return this.buffer;
endfunction  // getString


function string spi_master_base::popString();
    string _str;
    _str = getString();

    this.flush();
    return _str;
endfunction  // popString

//-----------------------------------------------------------------------------
// Title       : System Function
// Description :
//-----------------------------------------------------------------------------

function spi_master_base::flush();
    this.buffer = "";
    this.empty  = 1;
endfunction  // flush



//-----------------------------------------------------------------------------
// Title       : Overriding Super Class
// Description :
//-----------------------------------------------------------------------------
function spi_master_base::print(string _msg = "");
    if (this.log_fd) begin
        this.putString(_msg);
        $fwrite(this.log_fd, "%s\n", this.popString());
    end else begin
        this.putString(_msg);
        $display(this.popString());
    end
endfunction

//-----------------------------------------------------------------------------
// Title       : Log File Configuration Function
// Description :
//-----------------------------------------------------------------------------
function spi_master_base::basicConfig(string filename = "dummy.log", log_t level = WARN);
    this.log_fd = $fopen(filename, "w");
endfunction

function spi_master_base::tableConfig(int w_cycle = 12, int w_label = 8, int w_name = 10, int w_msg = 64);
    this.w_cycle  = w_cycle;
    this.w_label = w_label;
    this.w_name  = w_name;
    this.w_msg   = w_msg;
endfunction  // tableConfig


//-----------------------------------------------------------------------------
// Title       : Entitiy Format
// Description :
//-----------------------------------------------------------------------------

function string spi_master_base::fmtLevel(log_t _level = INFO);
    string _label = this.fmtAlign(_level.name(), RIGHT, this.w_label);

    if (_level == WARN) _label = fmtStyle(_label, YELLOW);
    if (_level == INFO) _label = fmtStyle(_label, CYAN);
    if (_level == DONE) _label = fmtStyle(_label, GREEN);
    if (_level == ERROR) _label = fmtStyle(_label, RED);

    return _label;
endfunction


function string spi_master_base::fmtTime();
    string _cycle = $sformatf("%0t ns", $realtime);
    return this.fmtAlign(_cycle, RIGHT, this.w_cycle);
endfunction  // fmtTime

function string spi_master_base::fmtName();
    int _width = 12;
    return this.fmtAlign(this.name, LEFT, this.w_name);
endfunction  // fmtName

function string spi_master_base::fmtLog(log_t _level = INFO, string _msg = "");
    string _log;

    _log = this.fmtTime();
    _log = $sformatf("%s%s%s", _log, this.t_brk, this.fmtLevel(_level));
    _log = $sformatf("%s%s%s", _log, this.t_brk, this.fmtName());
    _log = $sformatf("%s%s%s", _log, this.t_brk, _msg);
    return _log;

endfunction  // fmtLog

//-----------------------------------------------------------------------------
// Title       : Print Log
//-----------------------------------------------------------------------------
function spi_master_base::printLog(log_t _level = INFO, string _msg = "");
    if (_level == DEBUG) this.putStyle(DARK);
    if (_level == PASS) this.putStyle(GREEN);
    if (_level == FAIL) this.putStyle(RED);
    if (_level == FAULT) this.putStyle(REVERSE);

    this.putString(fmtLog(_level, _msg));
    this.putStyle();
    this.print();
endfunction  // printLog


//-----------------------------------------------------------------------------
// Title       : Entitiy Format
// Description :
//-----------------------------------------------------------------------------

function spi_master_base::printDiv();
    string _str;
    string _brk;

    _brk = "-+-";

    _str = this.fmtRepeat("-", this.w_cycle);
    _str = $sformatf("%s%s%s", _str, _brk, this.fmtRepeat("-", this.w_label));
    _str = $sformatf("%s%s%s", _str, _brk, this.fmtRepeat("-", this.w_name));
    _str = $sformatf("%s%s%s", _str, _brk, this.fmtRepeat("-", this.w_msg));
    this.print(_str);
endfunction  // printDiv

function spi_master_base::printTag();
    string _tag;
    _tag = this.fmtAlign("TIME", RIGHT, this.w_cycle);
    _tag = $sformatf("%s%s%s", _tag, this.t_brk, this.fmtAlign("LABLE", RIGHT, this.w_label));
    _tag = $sformatf("%s%s%s", _tag, this.t_brk, this.fmtAlign("NAME", LEFT, this.w_name));
    _tag = $sformatf("%s%s%s", _tag, this.t_brk, this.fmtAlign("MESSAGE", LEFT, 8));
    this.print(_tag);
endfunction  // print_tlb

function spi_master_base::printTop(string _msg = "");
    if (_msg == "") begin
        this.printDiv();
    end else begin
        this.printMsg(_msg);
    end
    this.printTag();
    this.printDiv();
endfunction


function spi_master_base::printMsg(string _msg = "");
    this.printDiv();
    this.print(_msg);
    this.printDiv();
endfunction

//-----------------------------------------------------------------------------
// Title       : Log Package Function
//-----------------------------------------------------------------------------

function spi_master_base::debug(string _str);
    if (this.level <= DEBUG) begin
        this.printLog(DEBUG, _str);
    end
endfunction

function spi_master_base::info(string _str);
    if (this.level <= INFO) begin
        this.printLog(INFO, _str);
    end
endfunction

function spi_master_base::done(string _str);
    if (this.level <= DONE) begin
        this.printLog(DONE, _str);
    end
endfunction

function spi_master_base::pass(string _str);
    if (this.level <= PASS) begin
        this.printLog(PASS, _str);
    end
endfunction

function spi_master_base::warn(string _str);
    if (this.level <= WARN) begin
        this.printLog(WARN, _str);
    end
endfunction

function spi_master_base::error(string _str);
    if (this.level <= ERROR) begin
        this.printLog(ERROR, _str);
    end
endfunction

function spi_master_base::fail(string _str);
    if (this.level <= FAIL) begin
        this.printLog(FAIL, _str);
    end
endfunction

function spi_master_base::fault(string _str);
    if (this.level <= FAULT) begin
        this.printLog(FAULT, _str);
    end
endfunction

//-----------------------------------------------------------------------------
// Title       : User Interface Function
//-----------------------------------------------------------------------------
task spi_master_base::watchdog(int _cycle = 1);
    this.info($sformatf("Watchdog timer Requested (%0d Cycle)", _cycle)); 
    repeat(_cycle) @(intf.cb);
    this.done($sformatf("Watchdog timer Finished (%0d Cycle)", _cycle)); 
endtask // watchdog

task spi_master_base::waitrun(int _cycle = 1);
    repeat(_cycle) @(intf.cb);
endtask // watchdog

task spi_master_base::reset(int _cycle = 4);
    this.info("Core reset requested");
    intf.rst_n            = 0;
    repeat(_cycle) @(intf.cb);
    intf.rst_n            = 1;
    this.done("Core reset finished");
endtask

task spi_master_base::init(int _cycle = 1);
    this.info("Core input init requested");
    
    intf.rst_n            = 0; 
    intf.miso_i           = 0; 
    intf.tx_byte_i        = 0; 
    intf.tx_byte_valid_i  = 0; 
    repeat(_cycle) @(intf.cb);
    this.done("Core input init finished");
endtask
task spi_master_base::set_miso_i(bit  _miso_i = 0, int _log = 1);
    intf.miso_i = _miso_i;
    if(_log) begin
        this.info($sformatf(" * SET miso_i                = %0d", _miso_i));
    end
endtask
task spi_master_base::dbg_mosi_o();
    bit  _mosi_o;
    _mosi_o = intf.mosi_o;
    this.info("Debug mosi_o started");
    while(1) begin
        @(intf.cb);
        if(_mosi_o != intf.mosi_o) begin
            if(intf.mosi_o) begin
                this.debug(" H___/``` mosi_o           0 > 1");
            end else begin
                this.debug(" L```\\___ mosi_o           1 > 0");
            end
        end
        _mosi_o = intf.mosi_o;
    end
endtask
task spi_master_base::dbg_sck_o();
    bit  _sck_o;
    _sck_o = intf.sck_o;
    this.info("Debug sck_o started");
    while(1) begin
        @(intf.cb);
        if(_sck_o != intf.sck_o) begin
            if(intf.sck_o) begin
                this.debug(" H___/``` sck_o            0 > 1");
            end else begin
                this.debug(" L```\\___ sck_o            1 > 0");
            end
        end
        _sck_o = intf.sck_o;
    end
endtask
task spi_master_base::dbg_cs_n_o();
    bit  _cs_n_o;
    _cs_n_o = intf.cs_n_o;
    this.info("Debug cs_n_o started");
    while(1) begin
        @(intf.cb);
        if(_cs_n_o != intf.cs_n_o) begin
            if(intf.cs_n_o) begin
                this.debug(" H___/``` cs_n_o           0 > 1");
            end else begin
                this.debug(" L```\\___ cs_n_o           1 > 0");
            end
        end
        _cs_n_o = intf.cs_n_o;
    end
endtask
task spi_master_base::set_tx_byte_i(bit [7:0] _tx_byte_i = 0, int _log = 1);
    intf.tx_byte_i = _tx_byte_i;
    if(_log) begin
        this.info($sformatf(" * SET tx_byte_i             = 0x%x (%0d)", _tx_byte_i, _tx_byte_i));
    end
endtask
task spi_master_base::set_tx_byte_valid_i(bit  _tx_byte_valid_i = 0, int _log = 1);
    intf.tx_byte_valid_i = _tx_byte_valid_i;
    if(_log) begin
        this.info($sformatf(" * SET tx_byte_valid_i       = %0d", _tx_byte_valid_i));
    end
endtask
task spi_master_base::dbg_ready_o();
    bit  _ready_o;
    _ready_o = intf.ready_o;
    this.info("Debug ready_o started");
    while(1) begin
        @(intf.cb);
        if(_ready_o != intf.ready_o) begin
            if(intf.ready_o) begin
                this.debug(" H___/``` ready_o          0 > 1");
            end else begin
                this.debug(" L```\\___ ready_o          1 > 0");
            end
        end
        _ready_o = intf.ready_o;
    end
endtask
task spi_master_base::dbg_rx_byte_o();
    bit [7:0] _rx_byte_o;
    _rx_byte_o = intf.rx_byte_o;
    this.info("Debug rx_byte_o started");
    while(1) begin
        @(intf.cb);
        if(_rx_byte_o != intf.rx_byte_o) begin
                this.debug($sformatf(" X___/ABC rx_byte_o        changed 0x%x > 0x%x", _rx_byte_o, intf.rx_byte_o));
        end
        _rx_byte_o = intf.rx_byte_o;
    end
endtask
task spi_master_base::dbg_rx_byte_valid_o();
    bit  _rx_byte_valid_o;
    _rx_byte_valid_o = intf.rx_byte_valid_o;
    this.info("Debug rx_byte_valid_o started");
    while(1) begin
        @(intf.cb);
        if(_rx_byte_valid_o != intf.rx_byte_valid_o) begin
            if(intf.rx_byte_valid_o) begin
                this.debug(" H___/``` rx_byte_valid_o  0 > 1");
            end else begin
                this.debug(" L```\\___ rx_byte_valid_o  1 > 0");
            end
        end
        _rx_byte_valid_o = intf.rx_byte_valid_o;
    end
endtask

`endif
