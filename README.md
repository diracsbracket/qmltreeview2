# qmltreeview2
This repository provides a self-contained QML `TreeView` implementation that
only depends on QtQuick 2 imports. The Qt `filessytembrowser` example is used
to demonstrate this.

![alt text](https://github.com/diracsbracket/qmltreeview2/blob/master/treeview.png?raw=true)

DESCRIPTION
-----------
The QML `TreeView` component is only provided as part of the now deprecated 
(since Qt 5.12) QtQuick Controls 1 module.

As it turns out, the original QtQuick 1 `TreeView` is mainly implemented around 
the QML types `ScrollView`, `ListView` and `FocusScope`, all of which have their
equivalents in QtQuick 2. As such, the `TreeView` code can be adapted to depend 
exclusively on QtQuick 2 imports.

The `TreeView.qml` file provided here aggregates all the QML code required for the 
`TreeView` into a single file.

To make it completely self-contained, all it requires are local copies of the 
`TableViewColumn.qml` file (which only depends on QtQuick 2) and the source 
files for the  `QQuickTreeModelAdaptor` class ( which only implements a 
`QAbstractItemModel`). These 3 ancillary files are also included in the example
shown here. Other than having renamed the C++ class to `TreeModelAdaptor`, the code 
of these 3 files are identical to their original version.

LIMITATIONS
-----------
The QML code in `TreeView.qml` was mostly copied as-is from the original Qt source,
except for the styling parts which have been eliminated and replaced by hard
settings. (Almost all) the modified parts are indicated by comments tagged with
the words `EDIT` and `ADDED`.

Finally, references to scrollbar settings have been commented out. Given that the 
code is available within a single file, it should be straightforward to apply 
the desired styling or to restore the scrollbar functionality.

The above example was only tested on Debian Buster and PiOS both with Qt 5.15.2

Cheers.
