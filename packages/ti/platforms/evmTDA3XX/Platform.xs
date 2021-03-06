/*
 * Copyright (c) 2016, Texas Instruments Incorporated
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * *  Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * *  Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * *  Neither the name of Texas Instruments Incorporated nor the names of
 *    its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 *  ======== Platform.xs ========
 *  Platform support for evmTDA3XX
 *
 */

var Utils = xdc.useModule('xdc.platform.Utils');

/*
 *  ======== Platform.getCpuDataSheet ========
 *  This Platform's implementation xdc.platform.IPlatform.getCpuDataSheet.
 *
 *  Return the xdc.platform.ICpuDataSheet.Instance object that corresponds
 *  to the device that runs executables loaded on the specified cpuId.
 */
function getCpuDataSheet(cpuId)
{
    if (cpuId == "0") {
        return (Utils.getCpuDataSheet(this.$module.DSP));
    }
    else if (cpuId == "1") {
        return (Utils.getCpuDataSheet(this.$module.M4));
    }
    else if (cpuId == "2") {
        return (Utils.getCpuDataSheet(this.$module.EVE));
    }
    else {
        this.$module.$logError("The platform " + this.$module.$name +
            " does not contain cpu with cpuId: " + cpuId, this.$module, null);
    }
}

/*
 *  ======== Platform.getExeContext ========
 *  This Platform's implementation xdc.platform.IPlatform.getExeContext.
 *
 *  Return the xdc.platform.IPlatform.ExeContext object that will run the
 *  specified program prog.
 */
function getExeContext(prog)
{
    var ExeContext = xdc.useModule('xdc.platform.ExeContext');

    /* create a default ExeContext execution context */
    var cpu;
    var core = this.$private.core;

    xdc.loadPackage(this.$module[core].catalogName);
    cpu = ExeContext.create(this.$module[core], this.$module.BOARD);
    cpu.memoryMap = Utils.assembleMemoryMap(cpu, this);

    if (this.codeMemory == undefined) {
        switch(core) {
            case "DSP":
                this.codeMemory = "EXT_RAM";
                break;
            case "M4":
                this.codeMemory = "EXT_RAM";
                break;
            case "EVE":
                this.codeMemory = "EXT_RAM";
                break;
        }
    }

    if (this.dataMemory == undefined) {
        switch(core) {
            case "DSP":
                this.dataMemory = "EXT_RAM";
                break;
            case "M4":
                this.dataMemory = "EXT_RAM";
                break;
            case "EVE":
                this.dataMemory = "DMEM";
                break;
        }
    }

    if (this.stackMemory == undefined) {
        switch(core) {
            case "DSP":
                this.stackMemory = "EXT_RAM";
                break;
            case "M4":
                this.stackMemory = "EXT_RAM";
                break;
            case "EVE":
                this.stackMemory = "DMEM";
                break;
        }
    }

    // check for the overlap in the memory map
    var overlap = Utils.checkOverlap(cpu.memoryMap);

    if (overlap != null) {
        this.$module.$logError("Memory objects " + overlap + " overlap", this,
            overlap);
    }

    this.$seal();

    return (cpu);
}

/*
 *  ======== Platform.getExecCmd ========
 *  This Platform's implementation xdc.platform.IPlatform.getExecCmd.
 */
function getExecCmd(prog)
{
    var os = environment["xdc.hostOS"];
    var updateComment = "@$(ECHO) Check for updates to this package at:\n" +
    "@$(ECHO) http://software-dl.ti.com/dsps/dsps_public_sw/sdo_sb/targetcontent/rtsc/index.html";

     return("@$(ECHO) " + this.$package.$name + " platform package cannot " +
         "execute " + prog.name + " on " + os + "\n" + updateComment +
         "\n\t:");
}

/*
 *  ======== Platform.getLinkTemplate ========
 *  This is Platform's implementation xdc.platform.IPlatform.getLinkTemplate
 */
function getLinkTemplate(prog)
{
    /* use the target's linker command template */
    /* we compute the target because this same platform is supported by
     * many different tool chains; e.g., ti.targets, gnu.targets, ...
     */
    var tname = prog.build.target.$name;
    var tpkg = tname.substring(0, tname.lastIndexOf('.'));
    var tmplName = "/linkcmd.xdt";

    /* Use bare metal linker command file if appropriate */
    if (Program.build.target.$name.match(/gnu.targets.arm.M/)) {
        tmplName = "/linkcmd_bm_v7a.xdt";
    }
    var templateName = tpkg.replace(/\./g, "/") + tmplName;

    if (xdc.findFile(templateName) != null) {
        return (templateName);
    }
    else if (tname.indexOf("ti.targets.") == 0) {
        tmplName = "/linkcmd.xdt";
        return ("ti/targets/linkcmd.xdt");
    }
    else {
        throw new Packages.xdc.services.global.XDCException(
            this.$package.$name + ".LINK_TEMPLATE_ERROR",
            "Target package " + tpkg + " does not contain linker command "
            + "template '" + tmplName.substring(1) + "'.");
    }
}

/*
 *  ======== Platform.Instance.init ========
 *  This function is called to initialize a newly created instance of a
 *  platform.  Platform instances are created just prior to running
 *  program configuration scripts.
 *
 *  Platform instances may also be created in the build domain.
 *
 *  @param(name)        the name used to identify this instance (without
 *                      the package name prefix).
 */
function instance$meta$init(name)
{
    /* if not in config phase, do nothing */
    if (xdc.om.$name != "cfg") {
        return;
    }

    var thisMod = this.$module;

    /*  If given name matches a "named platform instance" from the xdc
     *  file, then use the create args specified for that named instance.
     */
    var args = {};

    if (name in thisMod) {
        args = thisMod[name];
    }

    var arp32 = ["arp32"];
    var armChain = ["v7M4"];
    var dspChain = ["66"];
    for (var i = 0; i < dspChain.length; i++) {
        if (dspChain[i] == Program.build.target.isa) {
            args.core = "DSP";
        }
    }
    for (var i = 0; i < armChain.length; i++) {
        if (armChain[i] == Program.build.target.isa) {
            args.core = "M4";
        }
    }
    for (var i = 0; i < arp32.length; i++) {
        if (arp32[i] == Program.build.target.isa) {
            args.core = "EVE";
        }
    }

    if (args.core == null) {
        this.$module.$logError("The build target " + Program.build.target.$name
            + " is incompatible with this platform.", this.$module, null);
    }

    if ("externalMemoryMap" in args) {

        /* The external map has to be of the right type for this check to
         * work.
         */
        var external = new xdc.om['xdc.platform.IPlatform'].MemoryMap(
            args.externalMemoryMap);
        if (!Utils.checkFit(this.$module.PARAMS.externalMemoryMap, external)) {
            this.$module.$logError("External memory map cannot fit in " +
                "the available space.", this, null);
        }
        this.externalMemoryMap = external;
    }

    if ("codeMemory" in args) {
        this.codeMemory = args.codeMemory;
    }

    if ("dataMemory" in args) {
        this.dataMemory = args.dataMemory;
    }

    if ("stackMemory" in args) {
        this.stackMemory = args.stackMemory;
    }

    if (args.core == "EVE") {
        /* add 'page' to the external memory map on ARP32(EVE) */
        for (memory in this.externalMemoryMap) {
            if (memory.match(/EVEVECS/)) {
                this.externalMemoryMap[memory].page = 0;
            }
            else {
                this.externalMemoryMap[memory].page = 1;
            }
        }
    }

    /* Save 'core' to avoid computing it again */
    this.$private.core = args.core;
}
