/* 
 *  Copyright (c) 2014-2016 Texas Instruments. All rights reserved.
 *  This program and the accompanying materials are made available under the
 *  terms of the Eclipse Public License v1.0 and Eclipse Distribution License
 *  v. 1.0 which accompanies this distribution. The Eclipse Public License is
 *  available at http://www.eclipse.org/legal/epl-v10.html and the Eclipse
 *  Distribution License is available at
 *  http://www.eclipse.org/org/documents/edl-v10.php.
 *
 *  Contributors:
 *      Texas Instruments - initial implementation
 * */

/*
 *  ======== Settings.xdc ========
 */

package ti.targets.rts7000;

/*!
 *  ======== Settings ========
 *  Collection of parameters relevant for this package as a whole
 *
 */

module Settings {

    /*!
     *  ======== bootOnly ========
     *  Allow supplying only the boot code library
     *
     *  This package can supply the boot code and the library with the
     *  implementation of xdc.runtime modules. If this parameter is set to
     *  `true`, only the boot code is supplied. Otherwise, both the boot code
     *  and the xdc.runtime implementation are supplied.
     */
    metaonly config Bool bootOnly = false;
}
/*

 */

