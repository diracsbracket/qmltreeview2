import QtQuick 2.15

//REPLACED Controls 1 BY Controls 2
import QtQuick.Controls 2.15

import QtQml.Models 2.15

//ADDED: FOR TreeModelAdaptor
import com.example 1.0

ScrollView {
    id: root

    property bool alternatingRowColors: true

    //EDIT: ADDED
    property color backgroundColor: "white"
    property color alternateBackgroundColor: "lightgrey"
    property color textColor: "black"
    property real rowFontSize: 20
    property real rowHeight: 20

    //TODO: MAKE THIS A SINGLETON: enum NOT AVAILABLE IN GLOBAL Qt. NAMESPACE
    //Enum values according to: https://doc.qt.io/qt-5/qabstracstitemview.html#enumSelectionMode-enum

    //NOTE: VALUES BELOW ARE NOT LISTED IN NUMERICAL ORDER!
    //SelectionMode { SingleSelection, ContiguousSelection, ExtendedSelection, MultiSelection, NoSelection }
    QtObject {
        id: enumSelectionMode
        property int noSelection: 0
        property int singleSelection: 1
        property int multiSelection: 2
        property int extendedSelection: 3
        property int contiguousSelection: 4
    }
    //END ADDED

    property int selectionMode: enumSelectionMode.singleSelection

    property bool headerVisible: true
    property alias backgroundVisible: colorRect.visible

    //EDIT: FROM BasicTableViewStyle
    property Component itemDelegate: Item {
            height: rowHeight //Math.max(16, label.implicitHeight)
            property int implicitWidth: label.implicitWidth + 20

            Text {
                id: label
                width: parent.width - x - (horizontalAlignment === Text.AlignRight ? 8 : 1)
                x: (styleData.hasOwnProperty("depth") && styleData.column === 0) ? 0 :
                   horizontalAlignment === Text.AlignRight ? 1 : 8

                horizontalAlignment: Text.AlignLeft //styleData.textAlignment

                //EDIT
                verticalAlignment: Text.AlignVCenter

                //EDIT
                font.pixelSize: rowFontSize

                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1

                elide: styleData.elideMode
                text: styleData.value !== undefined ? styleData.value.toString() : ""
                color: styleData.textColor

                //EDIT
                //renderType: Settings.isMobile ? Text.QtRendering : Text.NativeRendering
                renderType: Text.NativeRendering

            }
        }

    //EDIT: COPIED FROM BasicTableViewStyle
    property Component rowDelegate: Rectangle {
        height: rowHeight //Math.round(TextSingleton.implicitHeight * 1.2)

        property color selectedColor: root.activeFocus ? "#07c" : "#999"

        color: styleData.selected ? selectedColor :
                                    !styleData.alternate ? alternateBackgroundColor : backgroundColor
    }

    //EDIT: COPIED FROM BasicTableViewStyle
    property Component headerDelegate:
        //EDIT: REPLACED BorderImage by Rectangle
        Rectangle {
        height: rowHeight // Math.round(textItem.implicitHeight * 1.2)
        color: "gray"

        Text {
            id: textItem
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft //styleData.textAlignment
            anchors.leftMargin: horizontalAlignment === Text.AlignLeft ? 12 : 1
            anchors.rightMargin: horizontalAlignment === Text.AlignRight ? 8 : 1
            text: styleData.value
            elide: Text.ElideRight
            color: textColor

            //EDIT
            //renderType: Settings.isMobile ? Text.QtRendering : Text.NativeRendering
            renderType: Text.NativeRendering

            //EDIT
            font.pixelSize: rowFontSize
        }
        Rectangle {
            width: 1
            height: parent.height - 2
            y: 1
            color: "#ccc"
        }
    }

    property int sortIndicatorColumn
    property bool sortIndicatorVisible: false
    property int sortIndicatorOrder: Qt.AscendingOrder
    property alias contentHeader: listView.header
    property alias contentFooter: listView.footer
    readonly property alias columnCount: columnModel.count
    property alias section: listView.section

    function addColumn(column) {
        return insertColumn(columnCount, column)
    }

    function insertColumn(index, column) {
        //if (__isTreeView && index === 0 && columnCount > 0) {
        if (index === 0 && columnCount > 0) {
            console.warn("TreeView::insertColumn(): Can't replace column 0")
            return null
        }
        var object = column
        if (typeof column['createObject'] === 'function') {
            object = column.createObject(root)
        } else if (object.__view) {
            console.warn("TreeView::insertColumn(): you cannot add a column to multiple views")
            return null
        }
        if (index >= 0 && index <= columnCount && object.accessibleRole === Accessible.ColumnHeader) {
            object.__view = root
            columnModel.insert(index, {columnItem: object})
            if (root.__columns[index] !== object) {
                // The new column needs to be put into __columns at the specified index
                // so the list needs to be recreated to be correct
                var arr = []
                for (var i = 0; i < index; ++i)
                    arr.push(root.__columns[i])
                arr.push(object)
                for (i = index; i < root.__columns.length; ++i)
                    arr.push(root.__columns[i])
                root.__columns = arr
            }
            return object
        }

        if (object !== column)
            object.destroy()
        console.warn("TreeView::insertColumn(): invalid argument")
        return null
    }

    function removeColumn(index) {
        if (index < 0 || index >= columnCount) {
            console.warn("TreeView::removeColumn(): invalid argument")
            return
        }
        if (__isTreeView && index === 0) {
            console.warn("TreeView::removeColumn(): Can't remove column 0")
            return
        }
        var column = columnModel.get(index).columnItem
        columnModel.remove(index, 1)
        column.destroy()
    }

    function moveColumn(from, to) {
        if (from < 0 || from >= columnCount || to < 0 || to >= columnCount) {
            console.warn("TreeView::moveColumn(): invalid argument")
            return
        }
        if (__isTreeView && to === 0) {
            console.warn("TreeView::moveColumn(): Can't move column 0")
            return
        }
        if (sortIndicatorColumn === from)
            sortIndicatorColumn = to
        columnModel.move(from, to, 1)
    }

    function getColumn(index) {
        if (index < 0 || index >= columnCount)
            return null
        return columnModel.get(index).columnItem
    }

    function resizeColumnsToContents () {
        for (var i = 0; i < __columns.length; ++i) {
            var col = getColumn(i)
            var header = __listView.headerItem.headerRepeater.itemAt(i)
            if (col) {
                col.resizeToContents()
                if (col.width < header.implicitWidth)
                    col.width = header.implicitWidth
            }
        }
    }

    // Internal stuff. Do not look
    Component.onCompleted: {
        for (var i = 0; i < __columns.length; ++i) {
            var column = __columns[i]
            if (column.accessibleRole === Accessible.ColumnHeader)
                addColumn(column)
        }
    }

    activeFocusOnTab: true

    implicitWidth: 200
    implicitHeight: 150

    /*
    //EDIT: NOT IN CONTROLS 2 VERSION OF ScrollView
    frameVisible: true
    */

    /*
    //EDIT: TODO: RESTORE SCROLLBAR FUNCTIONALITY
    __scrollBarTopMargin: headerVisible && (listView.transientScrollBars || Qt.platform.os === "osx")
                          ? listView.headerItem.height : 0
    */

    default property alias __columns: root.data
    property alias __currentRowItem: listView.currentItem
    property alias __currentRow: listView.currentIndex
    readonly property alias __listView: listView

    property Component __itemDelegateLoader: null
    property var __model

    //EDIT
    property bool __activateItemOnSingleClick: false //__style ? __style.activateItemOnSingleClick : false
    property Item __mouseArea

    ListView {
        id: listView
        focus: true

        //ADDED
        clip: true

        activeFocusOnTab: false
        Keys.forwardTo: [__mouseArea]
        anchors.fill: parent
        contentWidth: headerItem.headerRow.width + listView.vScrollbarPadding
        // ### FIXME Late configuration of the header item requires
        // this binding to get the header visible after creation
        contentY: -headerItem.height

        currentIndex: -1
        visible: columnCount > 0
        interactive: true //Settings.hasTouchScreen
        property var rowItemStack: [] // Used as a cache for rowDelegates

        /*
        //EDIT
        readonly property bool transientScrollBars: __style && !!__style.transientScrollBars
        readonly property real vScrollbarPadding: __scroller.verticalScrollBar.visible
                                                  && !transientScrollBars && Qt.platform.os === "osx" ?
                                                  __verticalScrollBar.width + __scroller.scrollBarSpacing + root.__style.padding.right : 0
       */

        /*
        readonly property bool transientScrollBars: true //__style && !!__style.transientScrollBars
        readonly property real vScrollbarPadding: __scroller.verticalScrollBar.visible
                                                  && !transientScrollBars ?
                                                  __verticalScrollBar.width + __scroller.scrollBarSpacing : 0
        */

        function incrementCurrentIndexBlocking() {
            var oldIndex = __listView.currentIndex
            //__scroller.blockUpdates = true;
            incrementCurrentIndex();
            //__scroller.blockUpdates = false;
            return oldIndex !== __listView.currentIndex
        }

        function decrementCurrentIndexBlocking() {
            var oldIndex = __listView.currentIndex
            //__scroller.blockUpdates = true;
            decrementCurrentIndex();
            //__scroller.blockUpdates = false;
            return oldIndex !== __listView.currentIndex
        }

        /*
        function scrollIfNeeded(key) {
            var diff = key === Qt.Key_PageDown ? height :
                       key === Qt.Key_PageUp ? -height : 0
            if (diff !== 0)
                __verticalScrollBar.value += diff
        }
        */

        SystemPalette {
            id: palette
            colorGroup: enabled ? SystemPalette.Active : SystemPalette.Disabled
        }

        Rectangle {
            id: colorRect
            parent: listView

            anchors.fill: parent
            color: palette.base
            z: -2
        }

        // Fills extra rows with alternate color
        Column {
            id: rowfiller
            Loader {
                id: rowSizeItem
                sourceComponent: root.rowDelegate
                visible: false
                property QtObject styleData: QtObject {
                    property bool alternate: false
                    property bool selected: false
                    property bool hasActiveFocus: false
                    property bool pressed: false
                }
            }
            property int rowHeight: Math.floor(rowSizeItem.implicitHeight)
            property int paddedRowCount: rowHeight != 0 ? height/rowHeight : 0

            y: listView.contentHeight - listView.contentY + listView.originY
            width: parent.width
            visible: alternatingRowColors
            height: listView.model && listView.model.count ? (viewport.height - listView.contentHeight) : 0
            Repeater {
                model: visible ? parent.paddedRowCount : 0
                Loader {
                    width: rowfiller.width
                    height: rowfiller.rowHeight
                    sourceComponent: root.rowDelegate
                    property QtObject styleData: QtObject {
                        readonly property bool alternate: (index + __listView.count) % 2 === 1
                        readonly property bool selected: false
                        readonly property bool hasActiveFocus: false
                        readonly property bool pressed: false
                    }
                    readonly property var model: null
                    readonly property var modelData: null
                }
            }
        }

        ListModel { id: columnModel }

        highlightFollowsCurrentItem: true
        model: root.__model

        delegate: FocusScope {
            id: rowItemContainer

            activeFocusOnTab: false
            z: rowItem.activeFocus ? 0.7 : rowItem.itemSelected ? 0.5 : 0

            property Item rowItem
            // We recycle instantiated row items to speed up list scrolling

            Component.onDestruction: {
                // move the rowItem back in cache
                if (rowItem) {
                    rowItem.visible = false;
                    rowItem.parent = null;
                    rowItem.rowIndex = -1;
                    listView.rowItemStack.push(rowItem); // return rowItem to cache
                }
            }

            Component.onCompleted: {
                // retrieve row item from cache
                if (listView.rowItemStack.length > 0)
                    rowItem = listView.rowItemStack.pop();
                else
                    rowItem = rowComponent.createObject(listView);

                // Bind container to item size
                rowItemContainer.width = Qt.binding( function() { return rowItem.width });
                rowItemContainer.height = Qt.binding( function() { return rowItem.height });

                // Reassign row-specific bindings
                rowItem.rowIndex = Qt.binding( function() { return model.index });
                rowItem.itemModelData = Qt.binding( function() { return typeof modelData === "undefined" ? null : modelData });
                rowItem.itemModel = Qt.binding( function() { return model });
                rowItem.parent = rowItemContainer;
                rowItem.visible = true;
            }
        }

        Component {
            id: rowComponent

            FocusScope {
                id: rowitem
                visible: false

                property int rowIndex
                property var itemModelData
                property var itemModel
                property bool itemSelected: __mouseArea.selected(rowIndex)
                property bool alternate: alternatingRowColors && rowIndex % 2 === 1

                //EDIT
                readonly property color itemTextColor: itemSelected ? "blue" : "black"

                property Item branchDecoration: null

                width: itemrow.width
                height: rowstyle.height

                onActiveFocusChanged: {
                    if (activeFocus)
                        listView.currentIndex = rowIndex
                }

                Loader {
                    id: rowstyle
                    // row delegate
                    sourceComponent: rowitem.itemModel !== undefined ? root.rowDelegate : null
                    // Row fills the view width regardless of item size
                    // But scrollbar should not adjust to it
                    height: item ? item.height : 16

                    //EDIT
                    width: parent.width // + __horizontalScrollBar.width
                    x: listView.contentX

                    // these properties are exposed to the row delegate
                    // Note: these properties should be mirrored in the row filler as well
                    property QtObject styleData: QtObject {
                        readonly property int row: rowitem.rowIndex
                        readonly property bool alternate: rowitem.alternate
                        readonly property bool selected: rowitem.itemSelected
                        readonly property bool hasActiveFocus: rowitem.activeFocus
                        readonly property bool pressed: rowitem.rowIndex === __mouseArea.pressedRow
                    }
                    readonly property var model: rowitem.itemModel
                    readonly property var modelData: rowitem.itemModelData
                }
                Row {
                    id: itemrow
                    height: parent.height
                    Repeater {
                        model: columnModel

                        delegate: __itemDelegateLoader

                        onItemAdded: {
                            var columnItem = columnModel.get(index).columnItem
                            item.__rowItem = rowitem
                            item.__column = columnItem
                        }
                    }
                }
            }
        }

        headerPositioning: ListView.OverlayHeader
        header: Item {
            id: tableHeader
            visible: headerVisible

            //EDIT
            width: Math.max(headerRow.width + listView.vScrollbarPadding, listView.width)

            height: visible ? headerRow.height : 0

            property alias headerRow: row
            property alias headerRepeater: repeater
            Row {
                id: row

                Repeater {
                    id: repeater

                    property int targetIndex: -1
                    property int dragIndex: -1

                    model: columnModel

                    delegate: Item {
                        id: headerRowDelegate
                        readonly property int column: index
                        z:-index
                        width: modelData.width

                        //EDIT
                        implicitWidth: width //columnCount === 1 ? width /*+ __verticalScrollBar.width*/ : headerStyle.implicitWidth
                        visible: modelData.visible
                        height: headerStyle.height

                        //readonly property bool treeViewMovable: !__isTreeView || index > 0
                        readonly property bool treeViewMovable: index > 0

                        Loader {
                            id: headerStyle
                            sourceComponent: root.headerDelegate
                            width: parent.width
                            property QtObject styleData: QtObject {
                                readonly property string value: modelData.title
                                readonly property bool pressed: headerClickArea.pressed
                                readonly property bool containsMouse: headerClickArea.containsMouse
                                readonly property int column: index
                                readonly property int textAlignment: modelData.horizontalAlignment
                                readonly property bool resizable: modelData.resizable
                            }
                        }

                        Rectangle{
                            id: targetmark
                            width: parent.width
                            height:parent.height
                            opacity: (treeViewMovable && index === repeater.targetIndex && repeater.targetIndex !== repeater.dragIndex) ? 0.5 : 0
                            Behavior on opacity { NumberAnimation { duration: 160 } }
                            color: palette.highlight
                            visible: modelData.movable
                        }

                        MouseArea{
                            id: headerClickArea
                            drag.axis: Qt.YAxis
                            hoverEnabled: false //Settings.hoverEnabled
                            anchors.fill: parent
                            onClicked: {
                                if (sortIndicatorColumn === index)
                                    sortIndicatorOrder = sortIndicatorOrder === Qt.AscendingOrder ? Qt.DescendingOrder : Qt.AscendingOrder
                                sortIndicatorColumn = index
                            }
                            // Here we handle moving header sections
                            // NOTE: the direction is different from the master branch
                            // so this indicates that I am using an invalid assumption on item ordering
                            onPositionChanged: {
                                if (drag.active && modelData.movable && pressed && columnCount > 1) { // only do this while dragging
                                    for (var h = columnCount-1 ; h >= 0 ; --h) {
                                        if (headerRow.children[h].visible && drag.target.x + headerRowDelegate.width/2 > headerRow.children[h].x) {
                                            repeater.targetIndex = h
                                            break
                                        }
                                    }
                                }
                            }

                            onPressed: {
                                repeater.dragIndex = index
                            }

                            onReleased: {
                                if (repeater.targetIndex >= 0 && repeater.targetIndex !== index ) {
                                    var targetColumn = columnModel.get(repeater.targetIndex).columnItem
                                    if (targetColumn.movable && (!__isTreeView || repeater.targetIndex > 0)) {
                                        if (sortIndicatorColumn === index)
                                            sortIndicatorColumn = repeater.targetIndex
                                        columnModel.move(index, repeater.targetIndex, 1)
                                    }
                                }
                                repeater.targetIndex = -1
                                repeater.dragIndex = -1
                            }
                            drag.target: treeViewMovable && modelData.movable && columnCount > 1 ? draghandle : null
                        }

                        Loader {
                            id: draghandle
                            property QtObject styleData: QtObject{
                                readonly property string value: modelData.title
                                readonly property bool pressed: headerClickArea.pressed
                                readonly property bool containsMouse: headerClickArea.containsMouse
                                readonly property int column: index
                                readonly property int textAlignment: modelData.horizontalAlignment
                            }
                            parent: tableHeader
                            x: __implicitX
                            property double __implicitX: headerRowDelegate.x
                            width: modelData.width
                            height: parent.height
                            sourceComponent: root.headerDelegate
                            visible: headerClickArea.pressed
                            onVisibleChanged: {
                                if (!visible)
                                    x = Qt.binding(function () { return __implicitX })
                            }
                            opacity: 0.5
                        }


                        MouseArea {
                            id: headerResizeHandle
                            property int offset: 0
                            readonly property int minimumSize: 20
                            preventStealing: true
                            anchors.rightMargin: -width/2
                            width: 16 //Settings.hasTouchScreen ? Screen.pixelDensity * 3.5 : 16
                            height: parent.height
                            anchors.right: parent.right
                            enabled: modelData.resizable && columnCount > 0
                            onPositionChanged:  {
                                var newHeaderWidth = modelData.width + (mouseX - offset)
                                modelData.width = Math.max(minimumSize, newHeaderWidth)
                            }

                            onDoubleClicked: getColumn(index).resizeToContents()
                            onPressedChanged: if (pressed) offset=mouseX
                            cursorShape: enabled && repeater.dragIndex==-1 ? Qt.SplitHCursor : Qt.ArrowCursor
                        }
                    }
                }
            }

            Loader {
                property QtObject styleData: QtObject{
                    readonly property string value: ""
                    readonly property bool pressed: false
                    readonly property bool containsMouse: false
                    readonly property int column: -1
                    readonly property int textAlignment: Text.AlignLeft
                }

                anchors.top: parent.top
                anchors.right: parent.right
                anchors.bottom: headerRow.bottom
                sourceComponent: root.headerDelegate
                readonly property real __remainingWidth: parent.width - headerRow.width
                visible: __remainingWidth > 0
                width: __remainingWidth
                z:-1
            }
        }

        function columnAt(offset) {
            var item = listView.headerItem.headerRow.childAt(offset, 0)
            return item ? item.column : -1
        }
    }

    //FROM BasicTableView
    property var model: null
    property alias rootIndex: modelAdaptor.rootIndex

    readonly property var currentIndex: modelAdaptor.updateCount, modelAdaptor.mapRowToModelIndex(__currentRow)
    property ItemSelectionModel selection: null

    signal activated(var index)
    signal clicked(var index)
    signal doubleClicked(var index)
    signal pressAndHold(var index)
    signal expanded(var index)
    signal collapsed(var index)

    function isExpanded(index) {
        if (index.valid && index.model !== model) {
            console.warn("TreeView.isExpanded: model and index mismatch")
            return false
        }
        return modelAdaptor.isExpanded(index)
    }

    function collapse(index) {
        if (index.valid && index.model !== model)
            console.warn("TreeView.collapse: model and index mismatch")
        else
            modelAdaptor.collapse(index)
    }

    function expand(index) {
        if (index.valid && index.model !== model)
            console.warn("TreeView.expand: model and index mismatch")
        else
            modelAdaptor.expand(index)
    }

    function indexAt(x, y) {
        var obj = root.mapToItem(__listView.contentItem, x, y)
        return modelAdaptor.mapRowToModelIndex(__listView.indexAt(obj.x, obj.y))
    }

    //__viewTypeName: "TreeView"

    __model: TreeModelAdaptor {
        id: modelAdaptor
        model: root.model

        // Hack to force re-evaluation of the currentIndex binding
        property int updateCount: 0
        onModelReset: updateCount++
        onRowsInserted: updateCount++
        onRowsRemoved: updateCount++

        onExpanded: root.expanded(index)
        onCollapsed: root.collapsed(index)
    }

    __itemDelegateLoader: Loader {
            id: itemDelegateLoader

            width: __column ? __column.width : 0
            height: parent ? parent.height : 0
            visible: __column ? __column.visible : false

            property bool isValid: false
            sourceComponent: (__model === undefined || !isValid) ? null
                             : __column && __column.delegate ? __column.delegate : __itemDelegate

            // All these properties are internal
            property int __index: index
            property Item __rowItem: null
            property var __model: __rowItem ? __rowItem.itemModel : undefined
            property var __modelData: __rowItem ? __rowItem.itemModelData : undefined
            property TableViewColumn __column: null
            property Component __itemDelegate: null

            property var __mouseArea: mouseArea//null

            // These properties are exposed to the item delegate
            readonly property var model: __model
            readonly property var modelData: __modelData

            //EDIT
            readonly property int __itemIndentation: 30 * (styleData.depth + 1)

            property TreeModelAdaptor __treeModel: null

            // Exposed to the item delegate
            property QtObject styleData: QtObject {
                readonly property int row: __rowItem ? __rowItem.rowIndex : -1
                readonly property int column: __index
                readonly property int elideMode: __column ? __column.elideMode : Text.ElideLeft
                readonly property int textAlignment: __column ? __column.horizontalAlignment : Text.AlignLeft
                readonly property bool selected: __rowItem ? __rowItem.itemSelected : false
                readonly property bool hasActiveFocus: __rowItem ? __rowItem.activeFocus : false
                readonly property bool pressed: __mouseArea && row === __mouseArea.pressedRow && column === __mouseArea.pressedColumn
                readonly property color textColor: __rowItem ? __rowItem.itemTextColor : "black"
                readonly property string role: __column ? __column.role : ""
                readonly property var value: model && model.hasOwnProperty(role) ? model[role] : ""
                readonly property var index: model ? model["_q_TreeView_ModelIndex"] : __treeModel.index(-1,-1)
                readonly property int depth: model && column === 0 ? model["_q_TreeView_ItemDepth"] : 0
                readonly property bool hasChildren: model ? model["_q_TreeView_HasChildren"] : false
                readonly property bool hasSibling: model ? model["_q_TreeView_HasSibling"] : false
                readonly property bool isExpanded: model ? model["_q_TreeView_ItemExpanded"] : false

                //FROM TableViewItemDelegateLoader styleData QtObject:
                //SIGNAL HANDLERS ARE INHERITED + CANNOT BE OVERRIDDEN BY SIMPLY REDEFINITION
                onRowChanged: if (row !== -1) itemDelegateLoader.isValid = true
            }

            onLoaded: {
                item.x = Qt.binding(function() { return __itemIndentation})
                item.width = Qt.binding(function() { return width - __itemIndentation })
            }

            Loader {
                id: branchDelegateLoader
                active: __model !== undefined
                        && __index === 0
                        && styleData.hasChildren
                visible: itemDelegateLoader.width > __itemIndentation

                sourceComponent: Item {
                        //EDIT
                        width: 50 //indentation

                        //EDIT
                        height: rowHeight //16

                        Text {
                            visible: styleData.column === 0 && styleData.hasChildren
                            text: styleData.isExpanded ? "\u25bc" : "\u25b6"

                            //EDIT
                            font.pixelSize: rowFontSize
                            color: !root.activeFocus || styleData.selected ? styleData.textColor : "#666"

                            renderType: Text.NativeRendering
                            style: Text.PlainText
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: 2
                        }
                    }

                anchors.right: parent.item ? parent.item.left : undefined

                //EDIT
                anchors.rightMargin: 0 //__style.__indentation > width ? (__style.__indentation - width) / 2 : 0

                anchors.verticalCenter: parent.verticalCenter

                property QtObject styleData: itemDelegateLoader.styleData
                onLoaded: if (__rowItem) __rowItem.branchDecoration = item
            }

            __itemDelegate: root.itemDelegate
            __treeModel: modelAdaptor
        }

    onSelectionModeChanged: if (!!selection) selection.clear()

    __mouseArea: MouseArea {
        id: mouseArea

        parent: __listView
        width: __listView.width
        height: __listView.height
        z: -1
        propagateComposedEvents: true
        focus: true
        // If there is not a touchscreen, keep the flickable from eating our mouse drags.
        // If there is a touchscreen, flicking is possible, but selection can be done only by tapping, not by dragging.
        preventStealing: false // !Settings.hasTouchScreen

        property var clickedIndex: undefined
        property var pressedIndex: undefined
        property bool selectOnRelease: false
        property int pressedColumn: -1
        readonly property alias currentRow: root.__currentRow
        readonly property alias currentIndex: root.currentIndex

        // Handle vertical scrolling whem dragging mouse outside boundaries
        property int autoScroll: 0 // 0 -> do nothing; 1 -> increment; 2 -> decrement
        property bool shiftPressed: false // forward shift key state to the autoscroll timer

        Timer {
            running: mouseArea.autoScroll !== 0  //&& __verticalScrollBar.visible
            interval: 20
            repeat: true
            onTriggered: {
                var oldPressedIndex = mouseArea.pressedIndex
                var row
                if (mouseArea.autoScroll === 1) {
                    __listView.incrementCurrentIndexBlocking();
                    row = __listView.indexAt(0, __listView.height + __listView.contentY)
                    if (row === -1)
                        row = __listView.count - 1
                } else {
                    __listView.decrementCurrentIndexBlocking();
                    row = __listView.indexAt(0, __listView.contentY)
                }

                var index = modelAdaptor.mapRowToModelIndex(row)
                if (index !== oldPressedIndex) {
                    mouseArea.pressedIndex = index
                    var modifiers = mouseArea.shiftPressed ? Qt.ShiftModifier : Qt.NoModifier
                    mouseArea.mouseSelect(index, modifiers, true /* drag */)
                }
            }
        }

        function mouseSelect(modelIndex, modifiers, drag) {
            if (!selection) {
                maybeWarnAboutSelectionMode()
                return
            }

            if (selectionMode) {
                selection.setCurrentIndex(modelIndex, ItemSelectionModel.NoUpdate)
                if (selectionMode === enumSelectionMode.singleSelection) {
                    selection.select(modelIndex, ItemSelectionModel.ClearAndSelect)
                } else {
                    var selectRowRange = (drag && (selectionMode === enumSelectionMode.multiSelection
                                                   || (selectionMode === enumSelectionMode.extendedSelection
                                                       && modifiers & Qt.ControlModifier)))
                                         || modifiers & Qt.ShiftModifier
                    var itemSelection = !selectRowRange || clickedIndex === modelIndex ? modelIndex
                                        : modelAdaptor.selectionForRowRange(clickedIndex, modelIndex)

                    if (selectionMode === enumSelectionMode.multiSelection
                        || selectionMode === enumSelectionMode.extendedSelection && modifiers & Qt.ControlModifier) {
                        if (drag)
                            selection.select(itemSelection, ItemSelectionModel.ToggleCurrent)
                        else
                            selection.select(modelIndex, ItemSelectionModel.Toggle)
                    } else if (modifiers & Qt.ShiftModifier) {
                        selection.select(itemSelection, ItemSelectionModel.SelectCurrent)
                    } else {
                        clickedIndex = modelIndex // Needed only when drag is true
                        selection.select(modelIndex, ItemSelectionModel.ClearAndSelect)
                    }
                }
            }
        }

        function keySelect(keyModifiers) {
            if (selectionMode) {
                if (!keyModifiers)
                    clickedIndex = currentIndex
                if (!(keyModifiers & Qt.ControlModifier))
                    mouseSelect(currentIndex, keyModifiers, keyModifiers & Qt.ShiftModifier)
            }
        }

        function selected(row) {
            if (selectionMode === enumSelectionMode.noSelection)
                return false

            var modelIndex = null
            if (!!selection) {
                modelIndex = modelAdaptor.mapRowToModelIndex(row)
                if (modelIndex.valid) {
                    if (selectionMode === enumSelectionMode.singleSelection)
                        return selection.currentIndex === modelIndex
                    return selection.hasSelection && selection.isSelected(modelIndex)
                } else {
                    return false
                }
            }

            return row === currentRow
                   && (selectionMode === enumSelectionMode.singleSelection
                       || (selectionMode > enumSelectionMode.singleSelection && !selection))
        }

        function branchDecorationContains(x, y) {
            var clickedItem = __listView.itemAt(0, y + __listView.contentY)
            if (!(clickedItem && clickedItem.rowItem))
                return false
            var branchDecoration = clickedItem.rowItem.branchDecoration
            if (!branchDecoration)
                return false
            var pos = mapToItem(branchDecoration, x, y)
            return branchDecoration.contains(Qt.point(pos.x, pos.y))
        }

        function maybeWarnAboutSelectionMode() {
            if (selectionMode > enumSelectionMode.singleSelection)
                console.warn("TreeView: Non-single selection is not supported without an ItemSelectionModel.")
        }

        onPressed: {
            var pressedRow = __listView.indexAt(0, mouseY + __listView.contentY)
            pressedIndex = modelAdaptor.mapRowToModelIndex(pressedRow)
            pressedColumn = __listView.columnAt(mouseX)
            selectOnRelease = false
            __listView.forceActiveFocus()
            if (pressedRow === -1
                /*|| Settings.hasTouchScreen*/
                || branchDecorationContains(mouse.x, mouse.y)) {
                return
            }
            if (selectionMode === enumSelectionMode.extendedSelection
                && selection.isSelected(pressedIndex)) {
                selectOnRelease = true
                return
            }
            __listView.currentIndex = pressedRow
            if (!clickedIndex)
                clickedIndex = pressedIndex
            mouseSelect(pressedIndex, mouse.modifiers, false)
            if (!mouse.modifiers)
                clickedIndex = pressedIndex
        }

        onReleased: {
            if (selectOnRelease) {
                var releasedRow = __listView.indexAt(0, mouseY + __listView.contentY)
                var releasedIndex = modelAdaptor.mapRowToModelIndex(releasedRow)
                if (releasedRow >= 0 && releasedIndex === pressedIndex)
                    mouseSelect(pressedIndex, mouse.modifiers, false)
            }
            pressedIndex = undefined
            pressedColumn = -1
            autoScroll = 0
            selectOnRelease = false
        }

        onPositionChanged: {
            // NOTE: Testing for pressed is not technically needed, at least
            // until we decide to support tooltips or some other hover feature
            if (mouseY > __listView.height && pressed) {
                if (autoScroll === 1) return;
                autoScroll = 1
            } else if (mouseY < 0 && pressed) {
                if (autoScroll === 2) return;
                autoScroll = 2
            } else  {
                autoScroll = 0
            }

            if (pressed && containsMouse) {
                var oldPressedIndex = pressedIndex
                var pressedRow = __listView.indexAt(0, mouseY + __listView.contentY)
                pressedIndex = modelAdaptor.mapRowToModelIndex(pressedRow)
                pressedColumn = __listView.columnAt(mouseX)
                if (pressedRow > -1 && oldPressedIndex !== pressedIndex) {
                    __listView.currentIndex = pressedRow
                    mouseSelect(pressedIndex, mouse.modifiers, true /* drag */)
                }
            }
        }

        onExited: {
            pressedIndex = undefined
            pressedColumn = -1
            selectOnRelease = false
        }

        onCanceled: {
            pressedIndex = undefined
            pressedColumn = -1
            autoScroll = 0
            selectOnRelease = false
        }

        onClicked: {
            var clickIndex = __listView.indexAt(0, mouseY + __listView.contentY)
            if (clickIndex > -1) {
                var modelIndex = modelAdaptor.mapRowToModelIndex(clickIndex)
                if (branchDecorationContains(mouse.x, mouse.y)) {
                    if (modelAdaptor.isExpanded(modelIndex))
                        modelAdaptor.collapse(modelIndex)
                    else
                        modelAdaptor.expand(modelIndex)
                } else {
                    // compensate for the fact that onPressed didn't select on press: do it here instead
                    pressedIndex = modelAdaptor.mapRowToModelIndex(clickIndex)
                    pressedColumn = __listView.columnAt(mouseX)
                    selectOnRelease = false
                    __listView.forceActiveFocus()
                    __listView.currentIndex = clickIndex
                    if (!clickedIndex)
                        clickedIndex = pressedIndex
                    mouseSelect(pressedIndex, mouse.modifiers, false)
                    if (!mouse.modifiers)
                        clickedIndex = pressedIndex

                    if (root.__activateItemOnSingleClick && !mouse.modifiers)
                        root.activated(modelIndex)
                }
                root.clicked(modelIndex)
            }
        }

        onDoubleClicked: {
            var clickIndex = __listView.indexAt(0, mouseY + __listView.contentY)
            if (clickIndex > -1) {
                var modelIndex = modelAdaptor.mapRowToModelIndex(clickIndex)
                if (!root.__activateItemOnSingleClick)
                    root.activated(modelIndex)
                root.doubleClicked(modelIndex)
            }
        }

        onPressAndHold: {
            var pressIndex = __listView.indexAt(0, mouseY + __listView.contentY)
            if (pressIndex > -1) {
                var modelIndex = modelAdaptor.mapRowToModelIndex(pressIndex)
                root.pressAndHold(modelIndex)
            }
        }
    }
}
