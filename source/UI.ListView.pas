{*******************************************************}
{                                                       }
{       FMX UI ListView �����Ԫ                        }
{                                                       }
{       ��Ȩ���� (C) 2016 YangYxd                       }
{                                                       }
{*******************************************************}

unit UI.ListView;

interface

{$SCOPEDENUMS ON}

uses
  UI.Debug, UI.Utils, UI.Base, UI.Standard, UI.Utils.ArrayEx, UI.Ani,
  {$IFDEF MSWINDOWS}Windows, {$ENDIF}
  FMX.Utils, FMX.ImgList, FMX.MultiResBitmap, FMX.ActnList, System.Rtti, FMX.Consts,
  FMX.TextLayout, FMX.Objects, System.ImageList, System.RTLConsts,
  System.TypInfo, FMX.Graphics, System.Generics.Collections, System.Math,
  System.Classes, System.Types, System.UITypes, System.SysUtils, System.Math.Vectors,
  FMX.Types, FMX.StdCtrls, FMX.Platform, FMX.Controls, FMX.InertialMovement,
  FMX.Styles.Objects, FMX.Forms;

const
  ListViewType_Default = 0;
  ListViewType_Remove = -1;

type
  TListViewEx = class;

  TOnItemMeasureHeight = procedure(Sender: TObject; Index: Integer;
    var AHeight: Single) of object;
  TOnItemClick = procedure(Sender: TObject; ItemIndex: Integer; const ItemView: TControl) of object;
  TOnItemClickEx = procedure(Sender: TObject; ItemIndex: Integer; const ItemObject: TControl) of object;

  /// <summary>
  /// �б��������ӿ�
  /// </summary>
  IListAdapter = interface
    ['{5CC5F4AB-2D8C-4A84-98A7-51566E38EA47}']
    function GetCount: Integer;
    function GetItemID(const Index: Integer): Int64;
    function GetItem(const Index: Integer): Pointer;
    function IndexOf(const AItem: Pointer): Integer;
    function GetView(const Index: Integer; ConvertView: TViewBase; Parent: TViewGroup): TViewBase;
    function GetItemViewType(const Index: Integer): Integer;
    function IsEmpty: Boolean;
    function IsEnabled(const Index: Integer): Boolean;
    function ItemDefaultHeight: Single;
    procedure ItemMeasureHeight(const Index: Integer; var AHeight: Single);
    procedure Clear;
    procedure Repaint;
    procedure NotifyDataChanged;
    property Count: Integer read GetCount;
    property Items[const Index: Integer]: Pointer read GetItem; default;
  end;

  /// <summary>
  /// �б���ͼ״̬
  /// </summary>
  TListViewState = (None {��},
    PullDownStart {������ʼ}, PullDownOK {������λ}, PullDownFinish {�����ɿ�}, PullDownComplete {�������},
    PullUpStart {������ʼ}, PullUpOK {������λ}, PullUpFinish {�����ɿ�}, PullUpComplete {�������}
  );

  /// <summary>
  /// �б� Header �� Footer �ӿ�
  /// </summary>
  IListViewHeader = interface
    ['{44F6F649-D173-4BEC-A38D-F03436ED55BC}']
    /// <summary>
    /// ����״̬
    /// </summary>
    procedure DoUpdateState(const State: TListViewState;
      const ScrollValue: Double);
    /// <summary>
    /// ���ø���״̬Ҫ��ʾ����Ϣ
    /// </summary>
    procedure SetStateHint(const State: TListViewState; const Msg: string);
    function GetVisible: Boolean;
    /// <summary>
    /// ����״̬
    /// </summary>
    property Visible: Boolean read GetVisible;
  end;

  /// <summary>
  /// ���� Header �� Footer �¼�
  /// </summary>
  TOnInitHeader = procedure (Sender: TObject; var NewFooter: IListViewHeader) of object;

  PListItemPoint = ^TListItemPoint;
  TListItemPoint = record
    H: Single;
  end;

  TListDividerView = class(TView);   

  TListTextItem = class(TTextView)
  private const
    C_MinHeight = 48;
    C_FontSize = 15;
  end;

  TListViewItemCheck = class(TLinearLayout)
  private const
    C_MinHeight = 48;
    C_FontSize = 15;
  public
    TextView1: TTextView;
    CheckBox1: TCheckBox;
  end;

  TListViewItemSingle = class(TLinearLayout)
  private const
    C_MinHeight = 48;
    C_FontSize = 15;
  public
    TextView1: TTextView;
    RadioButton: TRadioButton;
  end;

  TListViewList = TList<TViewBase>;

  /// <summary>
  /// �б���ͼ��������
  /// </summary>
  TListViewContent = class(TViewGroup)
  private
    [Weak] ListView: TListViewEx;
    [Weak] FAdapter: IListAdapter;
    FIsDesigning: Boolean;

    FTimer: TTimer;
    FViews: TDictionary<Integer, TViewBase>;  // ��ǰ��ʾ�Ŀؼ��б�
    FCacleViews: TDictionary<Integer, TListViewList>; // ����Ŀؼ�

    FItemViews: TDictionary<Pointer, Integer>; // ��ǰ��ʾ�Ŀؼ���������
    FItemClick: TDictionary<Pointer, TNotifyEvent>; // ��ǰ��ʾ�Ŀؼ���ԭʼ�¼��ֵ�
    
    FFirstRowIndex: Integer;
    FLastRowIndex: Integer;
    FCount: Integer;

    FOffset: Double;
    FLastPosition: Double;
    FMaxParentHeight: Double;  // �����ؼ����߶ȣ���ֵ>0ʱ�������б�߶��Զ�������С)
    FViewBottom: Double;
    FDividerBrush: TBrush;

    FLastW, FLastH, FLastOffset: Single;

    FLastColumnCount: Integer;
    FLastColumnWidth: Single;

    FDownPos: TPointF;

    function GetVisibleRowCount: Integer;
    function GetControlFormCacle(const ItemType: Integer): TViewBase;
    procedure AddControlToCacle(const ItemType: Integer; const Value: TViewBase);
    function GetAbsoluteColumnCount: Integer;
    function GetAbsoluteColumnWidth: Single;
  protected 
    procedure DoRealign; override;
    procedure AfterPaint; override;
    procedure PaintBackground; override;
    procedure DrawDivider(Canvas: TCanvas);   // ���ָ���
    function ObjectAtPoint(AScreenPoint: TPointF): IControl; override;
    procedure DoChangeSize(var ANewWidth, ANewHeight: Single); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
  protected
    procedure DoItemClick(Sender: TObject);
    procedure DoItemChildClick(Sender: TObject);
    procedure DoFooterClick(Sender: TObject);
    procedure DoPaintFrame(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure DoMouseDownFrame(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure ClearViews;
    procedure HideViews;

  protected
    // ����ˢ�£��������ظ���
    FState: TListViewState;
    FHeader: IListViewHeader;
    FFooter: IListViewHeader;
    FPullOffset: Single;
    FCompleteTime: Int64;

    FColumnCount: Integer;
    FColumnWidth: Single;
    FColumnDivider: Boolean;

    FHeaderView: TControl;
    FFooterView: TControl;

    procedure InitFooter(); virtual;
    procedure InitHeader(); virtual;
    procedure FreeHeader(); virtual;
    procedure FreeFooter(); virtual;
    procedure DoPullLoadComplete; virtual;
    procedure DoPullRefreshComplete; virtual;
    procedure DoTimer(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    /// <summary>
    /// ���б�ͷ�����һ��View
    /// </summary>
    procedure AddHeaderView(const View: TControl); overload;
    function AddHeaderView(const View: TViewClass): TControl; overload;
    /// <summary>
    /// ɾ��������б�ͷ����View
    /// </summary>
    procedure RemoveHeaderView();

    /// <summary>
    /// ���б�ײ����һ��View
    /// </summary>
    procedure AddFooterView(const View: TControl); overload;
    function AddFooterView(const View: TViewClass): TControl; overload;
    /// <summary>
    /// ɾ��������б�ײ���View
    /// </summary>
    procedure RemoveFooterView();

    /// <summary>
    /// ��ǰ��ʾ������������
    /// </summary>
    property FirstRowIndex: Integer read FFirstRowIndex;
    /// <summary>
    /// ��ǰ��ʾ�����һ��������
    /// </summary>
    property LastRowIndex: Integer read FLastRowIndex;
    /// <summary>
    /// ��ǰ��ʾ�˼���
    /// </summary>
    property VisibleRowCount: Integer read GetVisibleRowCount;
    /// <summary>
    /// ��ǰ��ʵ��ʾ���б�
    /// </summary>
    property AbsoluteColumnCount: Integer read GetAbsoluteColumnCount;
    /// <summary>
    /// ��ǰ��ʵ��ʾ���п�
    /// </summary>
    property AbsoluteColumnWidth: Single read GetAbsoluteColumnWidth;
  end;

  /// <summary>
  /// �б����ͼ
  /// </summary>
  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TListViewEx = class(TScrollView)
  private const
    CDefaultDividerColor = $afe3e4e5;    // Ĭ�����зָ�����ɫ
    CDefaultBKPressedColor = $ffd9d9d9;  // Ĭ���б����ʱ������ɫ
  private
    FAdapter: IListAdapter;
    FDivider: TAlphaColor;
    FDividerHeight: Single;
    FItemsPoints: TArray<TListItemPoint>;
    FContentViews: TListViewContent;
    FLocalDividerHeight: Single;
    FAllowItemChildClick: Boolean;
    FLastHeight, FLastWidth: Single;
    FResizeing: Boolean;

    FEnablePullRefresh: Boolean;
    FEnablePullLoad: Boolean;
    FCount: Integer;

    FScrollbarWidth: Single;

    FOnDrawViewBackgroud: TOnDrawViewBackgroud;
    FOnItemMeasureHeight: TOnItemMeasureHeight;
    FOnItemClick: TOnItemClick;
    FOnItemClickEx: TOnItemClickEx;

    FOnInitFooter: TOnInitHeader;
    FOnInitHeader: TOnInitHeader;
    FOnPullRefresh: TNotifyEvent;
    FOnPullLoad: TNotifyEvent;

    procedure SetAdapter(const Value: IListAdapter);
    procedure SetDivider(const Value: TAlphaColor);
    procedure SetDividerHeight(const Value: Single);
    function GetItemPosition(Index: Integer): TListItemPoint;
    function GetFirstRowIndex: Integer;
    function GetLastRowIndex: Integer;
    function GetVisibleRowCount: Integer;
    function GetItemViews(Index: Integer): TControl;
    procedure SetEnablePullLoad(const Value: Boolean);
    procedure SetEnablePullRefresh(const Value: Boolean);
    function GetFooter: IListViewHeader;
    function GetHeader: IListViewHeader;
    function GetColumnCount: Integer;
    function GetColumnWidth: Single;
    function IsStoredColumnWidth: Boolean;
    procedure SetColumnCount(const Value: Integer);
    procedure SetColumnWidth(const Value: Single);
    function GetAbsoluteColumnCount: Integer;
    function GetAbsoluteColumnWidth: Single;
    function GetRowCount: Integer;
    function GetColumnDivider: Boolean;
    procedure SetColumnDivider(const Value: Boolean);
    procedure SetScrollbarWidth(const Value: Single);
    function IsStoredScrollbarWidth: Boolean;
  protected
    function CreateScroll: TScrollBar; override;
    function GetRealDrawState: TViewState; override;
    function CanRePaintBk(const View: IView; State: TViewState): Boolean; override;
    function IsStoredDividerHeight: Boolean; virtual;
  protected
    function GetCount: Integer;
    function IsEmpty: Boolean;
    procedure InvalidateContentSize(); override;
    procedure DoRealign; override;
    procedure DoInVisibleChange; override;
    procedure DoScrollVisibleChange; override;
    procedure DoChangeSize(var ANewWidth, ANewHeight: Single); override;

    procedure DoPullLoad(Sender: TObject);
    procedure DoColumnCountChange(const AColumnCount: Integer);

    procedure CMGesture(var EventInfo: TGestureEventInfo); override;
    procedure AniMouseUp(const Touch: Boolean; const X, Y: Single); override;
  protected
    procedure Resize; override;
    procedure Loaded; override;
    procedure PaintBackground; override;
    procedure DoDrawBackground(var R: TRectF); virtual;
    procedure DoPaintBackground(var R: TRectF); virtual;
    procedure CreateCoentsView();
    procedure HScrollChange(Sender: TObject); override;
    procedure VScrollChange(Sender: TObject); override;
    function InnerCalcDividerHeight: Single;
    function GetDividerHeight: Single;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // �������
    procedure Clear;
     
    // ֪ͨ���ݷ����ı�
    procedure NotifyDataChanged; virtual;

    // ˢ�����
    procedure PullRefreshComplete();
    // ���ظ������
    procedure PullLoadComplete();

    function IsEnabled(const Index: Integer): Boolean;

    /// <summary>
    /// ���б�ͷ�����һ��View
    /// </summary>
    procedure AddHeaderView(const View: TControl); overload;
    function AddHeaderView(const View: TViewClass): TControl; overload;
    /// <summary>
    /// ɾ��������б�ͷ����View
    /// </summary>
    procedure RemoveHeaderView();

    /// <summary>
    /// ���б�ײ����һ��View
    /// </summary>
    procedure AddFooterView(const View: TControl); overload;
    function AddFooterView(const View: TViewClass): TControl; overload;
    /// <summary>
    /// ɾ��������б�ײ���View
    /// </summary>
    procedure RemoveFooterView();

    property Count: Integer read GetCount;
    property Empty: Boolean read IsEmpty;
    property Adapter: IListAdapter read FAdapter write SetAdapter;
    property ItemPosition[Index: Integer]: TListItemPoint read GetItemPosition;
    property ItemViews[Index: Integer]: TControl read GetItemViews;
    property ContentViews: TListViewContent read FContentViews;

    /// <summary>
    /// ��ǰ��ʾ������������
    /// </summary>
    property FirstRowIndex: Integer read GetFirstRowIndex;
    /// <summary>
    /// ��ǰ��ʾ�����һ��������
    /// </summary>
    property LastRowIndex: Integer read GetLastRowIndex;
    /// <summary>
    /// ��ǰ��ʾ�˼���
    /// </summary>
    property VisibleRowCount: Integer read GetVisibleRowCount;
    /// <summary>
    /// ��ǰ��ʵ��ʾ���б�
    /// </summary>
    property AbsoluteColumnCount: Integer read GetAbsoluteColumnCount;
    /// <summary>
    /// ��ǰ��ʵ��ʾ���п�
    /// </summary>
    property AbsoluteColumnWidth: Single read GetAbsoluteColumnWidth;
    /// <summary>
    /// ������
    /// </summary>
    property RowCount: Integer read GetRowCount;

    property Header: IListViewHeader read GetHeader;
    property Footer: IListViewHeader read GetFooter;
  published
    /// <summary>
    /// �Ƿ��������б����е��ӿؼ��¼�
    /// </summary>
    property AllowItemClickEx: Boolean read FAllowItemChildClick write FAllowItemChildClick default True;
    /// <summary>
    /// ÿ����ʾ���������������� >= 1
    /// </summary>
    property ColumnCount: Integer read GetColumnCount write SetColumnCount default 1;
    /// <summary>
    /// ÿ�еĿ�ȣ�Ĭ��-1����ʾ����ÿ����ʾ�������Զ��������п�>0ʱ��ColumnCount ������Ч���������п��Զ�����
    /// </summary>
    property ColumnWidth: Single read GetColumnWidth write SetColumnWidth stored IsStoredColumnWidth;
    /// <summary>
    /// ��ʾ�зָ���
    /// </summary>
    property ColumnDivider: Boolean read GetColumnDivider write SetColumnDivider default True;
    /// <summary>
    /// �ָ�����ɫ
    /// </summary>
    property Divider: TAlphaColor read FDivider write SetDivider;
    /// <summary>
    /// �ָ��߸߶�
    /// </summary>
    property DividerHeight: Single read FDividerHeight write SetDividerHeight stored IsStoredDividerHeight;

    property ScrollStretchGlowColor;
    property ScrollbarWidth: Single read FScrollbarWidth write SetScrollbarWidth stored IsStoredScrollbarWidth;
    property OnScrollChange;

    property OnDrawBackgroud: TOnDrawViewBackgroud read FOnDrawViewBackgroud
      write FOnDrawViewBackgroud;
    /// <summary>
    /// �����߶��¼�
    /// </summary>
    property OnItemMeasureHeight: TOnItemMeasureHeight read FOnItemMeasureHeight
      write FOnItemMeasureHeight;
    /// <summary>
    /// �б������¼�
    /// </summary>
    property OnItemClick: TOnItemClick read FOnItemClick write FOnItemClick;
    /// <summary>
    /// �б����ڲ��ؼ�����¼�
    /// </summary>
    property OnItemClickEx: TOnItemClickEx read FOnItemClickEx write FOnItemClickEx;

    property HitTest default True;
    property Clickable default True;

    /// <summary>
    /// �Ƿ���������ˢ��
    /// </summary>
    property EnablePullRefresh: Boolean read FEnablePullRefresh write SetEnablePullRefresh;
    /// <summary>
    /// �Ƿ������������ظ���
    /// </summary>
    property EnablePullLoad: Boolean read FEnablePullLoad write SetEnablePullLoad;

    /// <summary>
    /// ���� Footer �¼�, ��������ã�������Ҫʱ����Ĭ�ϵ� Footer
    /// </summary>
    property OnInitFooter: TOnInitHeader read FOnInitFooter write FOnInitFooter;
    /// <summary>
    /// ���� Header �¼�, ��������ã�������Ҫʱ����Ĭ�ϵ� Header
    /// </summary>
    property OnInitHeader: TOnInitHeader read FOnInitHeader write FOnInitHeader;
    /// <summary>
    /// ����ˢ���¼�
    /// </summary>
    property OnPullRefresh: TNotifyEvent read FOnPullRefresh write FOnPullRefresh;
    /// <summary>
    /// �������ظ����¼�
    /// </summary>
    property OnPullLoad: TNotifyEvent read FOnPullLoad write FOnPullLoad;
  end;


  /// <summary>
  /// ListView ��������������
  /// </summary>
  TListAdapterBase = class(TInterfacedObject, IListAdapter)
  private
    [Weak] FListView: TListViewEx;
  protected
    procedure DoInitData; virtual;
    { IListAdapter }
    function GetItemID(const Index: Integer): Int64; virtual;
    function ItemDefaultHeight: Single; virtual;
    function GetItemViewType(const Index: Integer): Integer; virtual;
    function IsEmpty: Boolean;
    function IsEnabled(const Index: Integer): Boolean; virtual;
    procedure ItemMeasureHeight(const Index: Integer; var AHeight: Single); virtual;
  protected
    { IListAdapter }
    function GetCount: Integer; virtual; abstract;
    function GetItem(const Index: Integer): Pointer; virtual; abstract;
    function IndexOf(const AItem: Pointer): Integer; virtual; abstract;
    function GetView(const Index: Integer; ConvertView: TViewBase; Parent: TViewGroup): TViewBase; virtual; abstract;
  public
    constructor Create();

    procedure Clear; virtual;
    procedure Repaint; virtual;
    procedure NotifyDataChanged; virtual;

    property ListView: TListViewEx read FListView write FListView;
    property Count: Integer read GetCount;
    property Empty: Boolean read IsEmpty;
  end;

  /// <summary>
  /// ListView �������������ͻ���
  /// </summary>
  TListAdapter<T> = class(TListAdapterBase)
  private
    function GetItems: TList<T>;
    procedure SetItems(const Value: TList<T>);
  protected
    FList: TList<T>;
    FListNeedFree: Boolean;
    function GetCount: Integer; override;
  public
    constructor Create(const AItems: TList<T>); overload;
    destructor Destroy; override;
    procedure Clear; override;
    procedure Add(const Value: T);
    procedure Insert(const Index: Integer; const Value: T);
    procedure Delete(const Index: Integer);
    function Remove(const Value: T): Integer;
    property Items: TList<T> read GetItems write SetItems;
  end;

  /// <summary>
  /// ���ַ������ݽӿ�
  /// </summary>
  TStringsListAdapter = class(TListAdapterBase)
  private
    FFlags: Integer;
    FList: TStrings;
    FArray: TArrayEx<string>;
    function GetItemValue(const Index: Integer): string;
    procedure SetItemValue(const Index: Integer; const Value: string);
    procedure SetArray(const Value: TArray<string>);
    procedure SetList(const Value: TStrings);
    function GetList: TStrings;
    function GetArray: TArray<string>;
  protected
    FListNeedFree: Boolean;
    { IListAdapter }
    function GetCount: Integer; override;
    function GetItem(const Index: Integer): Pointer; override;
    function IndexOf(const AItem: Pointer): Integer; override;
    function GetView(const Index: Integer; ConvertView: TViewBase; Parent: TViewGroup): TViewBase; override;
    function ItemDefaultHeight: Single; override;
  public
    constructor Create(const AItems: TStrings); overload;
    constructor Create(const AItems: TArray<string>); overload;
    destructor Destroy; override;
    procedure Clear; override;
    procedure Add(const V: string); overload; virtual;
    procedure Add(const V: TArray<string>); overload; virtual;
    procedure Insert(const Index: Integer; const V: string); virtual;
    procedure Delete(const Index: Integer); virtual;
    procedure SetArrayLength(const ACount: Integer);
    property Items[const Index: Integer]: string read GetItemValue write SetItemValue; default;
    property Strings: TStrings read GetList write SetList;
    property StringArray: TArray<string> read GetArray write SetArray;
  end;

  /// <summary>
  /// ��ͼ����ַ����б�������
  /// </summary>
  TStringsListIconAdapter = class(TStringsListAdapter)
  private
    FImages: TCustomImageList;
    FIconSize: TSize;
    FPadding: Integer;
    FPosition: TDrawablePosition;
  protected
    function GetItemImageIndex(const Index: Integer): Integer; virtual;
    function GetView(const Index: Integer; ConvertView: TViewBase; Parent: TViewGroup): TViewBase; override;
    procedure DoInitData; override;
  public
    property Images: TCustomImageList read FImages write FImages;
    property IconSize: TSize read FIconSize write FIconSize;
    property Padding: Integer read FPadding write FPadding;
    property Position: TDrawablePosition read FPosition write FPosition;
  end;

  /// <summary>
  /// ��ѡ�б�������
  /// </summary>
  TStringsListCheckAdapter = class(TStringsListAdapter)
  private
    FChecks: TArrayEx<Boolean>;
    function GetItemCheck(const Index: Integer): Boolean;
    procedure SetItemCheck(const Index: Integer; const Value: Boolean);
    procedure SetChecks(const Value: TArray<Boolean>);
    function GetChecks: TArray<Boolean>;
  protected
    procedure DoCheckChange(Sender: TObject);
    function GetView(const Index: Integer; ConvertView: TViewBase; Parent: TViewGroup): TViewBase; override;
  public
    procedure Insert(const Index: Integer; const V: string); override;
    procedure Delete(const Index: Integer); override;
    property Checks: TArray<Boolean> read GetChecks write SetChecks;
    property ItemCheck[const Index: Integer]: Boolean read GetItemCheck write SetItemCheck;
  end;

  /// <summary>
  /// ��ѡ�б�������
  /// </summary>
  TStringsListSingleAdapter = class(TStringsListAdapter)
  private
    FItemIndex: Integer;
    procedure SetItemIndex(const Value: Integer);
  protected
    procedure DoInitData; override;
    procedure DoItemIndexChange(Sender: TObject);
    function GetView(const Index: Integer; ConvertView: TViewBase; Parent: TViewGroup): TViewBase; override;
  public
    property ItemIndex: Integer read FItemIndex write SetItemIndex;
  end;

type
  /// <summary>
  /// �����б�ڵ�����
  /// </summary>
  TTreeListNode<T> = class(TObject)
  private
    function GetCount: Integer;
    function GetNode(const Index: Integer): TTreeListNode<T>;
    procedure SetNode(const Index: Integer; const Value: TTreeListNode<T>);
    procedure SetParent(const Value: TTreeListNode<T>);
    function GetParentIndex: Integer;
  protected
    FParent: TTreeListNode<T>;
    FNodes: TList<TTreeListNode<T>>;
    FExpanded: Boolean;
    FLevel: Integer;
    FData: T;
    procedure DoNodeNotify(Sender: TObject; const Item: TTreeListNode<T>;
      Action: System.Generics.Collections.TCollectionNotification);
    procedure CreateNodes; virtual;
    procedure InnerRemove(const ANode: TTreeListNode<T>);
    procedure UpdateLevel;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;

    procedure Add(const ANode: TTreeListNode<T>);
    procedure Remove(const ANode: TTreeListNode<T>);
    procedure Insert(const Index: Integer; const ANode: TTreeListNode<T>);

    function AddNode(const AData: T): TTreeListNode<T>;
    function InsertNode(const Index: Integer; const AData: T): TTreeListNode<T>;

    property Data: T read FData write FData;
    property Count: Integer read GetCount;
    property Nodes[const Index: Integer]: TTreeListNode<T> read GetNode write SetNode; default;
    property Expanded: Boolean read FExpanded write FExpanded;
    property Parent: TTreeListNode<T> read FParent write SetParent;
    property Level: Integer read FLevel;
    property Index: Integer read GetParentIndex;
  end;

  /// <summary>
  /// �����б���������������
  /// </summary>
  TCustomTreeListDataAdapter<T> = class(TListAdapterBase)
  private
    FRoot: TTreeListNode<T>;
    FList: TList<TTreeListNode<T>>;
    FUpdateRef: Integer;
    function GetNodes(const Index: Integer): TTreeListNode<T>;
    function GetNodeCount: Integer;
    procedure AddListItem(const Parent: TTreeListNode<T>);
  protected
    function GetCount: Integer; override;
    function GetItem(const Index: Integer): Pointer; override;
    function IndexOf(const AItem: Pointer): Integer; override;
    function GetItemViewType(const Index: Integer): Integer; override;
    procedure ItemMeasureHeight(const Index: Integer; var AHeight: Single); override;

    function GetView(const Index: Integer; ConvertView: TViewBase;
      Parent: TViewGroup): TViewBase; override;

    function GetNodeGroupView(const Index: Integer; const ANode: TTreeListNode<T>;
      ConvertView: TViewBase; Parent: TViewGroup): TViewBase; virtual;
    function GetNodeItemView(const Index: Integer; const ANode: TTreeListNode<T>;
      ConvertView: TViewBase; Parent: TViewGroup): TViewBase; virtual;

    function GetNodeText(const ANode: TTreeListNode<T>): string; virtual;

    procedure InitList; virtual;
    procedure DoNodeExpandChange(Sender: TObject); virtual;
  public
    constructor Create(); virtual;
    destructor Destroy; override;
    procedure NotifyDataChanged; override;
    procedure Clear; override;

    procedure BeginUpdate;
    procedure EndUpdate;

    property Root: TTreeListNode<T> read FRoot;
    property Nodes[const Index: Integer]: TTreeListNode<T> read GetNodes;
    property NodeCount: Integer read GetNodeCount;
  end;

implementation

uses
  UI.ListView.Header, UI.ListView.Footer, UI.ListView.TreeGroup;

{ TListViewEx }

procedure TListViewEx.AddHeaderView(const View: TControl);
begin
  FContentViews.AddHeaderView(View);
end;

procedure TListViewEx.AddFooterView(const View: TControl);
begin
  FContentViews.AddFooterView(View);
end;

function TListViewEx.AddFooterView(const View: TViewClass): TControl;
begin
  Result := FContentViews.AddFooterView(View);
end;

function TListViewEx.AddHeaderView(const View: TViewClass): TControl;
begin
  Result := FContentViews.AddHeaderView(View);
end;

procedure TListViewEx.AniMouseUp(const Touch: Boolean; const X, Y: Single);
begin
  inherited AniMouseUp(Touch, X, Y);

  // ����ˢ�´���
  if FEnablePullRefresh then begin
    if Assigned(FContentViews) and (FContentViews.FState = TListViewState.PullDownOK) then begin
      FContentViews.FHeader.DoUpdateState(TListViewState.PullDownFinish, 0);
      FContentViews.FState := TListViewState.PullDownFinish;
      if Assigned(FOnPullRefresh) then
        FOnPullRefresh(Self); 
      Exit;
    end; 
  end;
  
  // �������ظ���
  if FEnablePullLoad then begin
    if Assigned(FContentViews) and (FContentViews.FState = TListViewState.PullUpOK) then
      DoPullLoad(Self);
  end;
end;

function TListViewEx.CanRePaintBk(const View: IView;
  State: TViewState): Boolean;
begin
  Result := (State = TViewState.None) and (not AniCalculations.Animation);
end;

procedure TListViewEx.Clear;
begin
  if Assigned(FAdapter) then begin
    FAdapter.Clear;
    NotifyDataChanged;
    FCount := 0;
  end;
end;

procedure TListViewEx.CMGesture(var EventInfo: TGestureEventInfo);
begin
  if Assigned(FContentViews) then begin
    if FContentViews.FState in [TListViewState.PullDownFinish, TListViewState.PullUpFinish] then
      Exit;  
  end;
  inherited CMGesture(EventInfo);
end;

constructor TListViewEx.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  New(FContentBounds);
  CreateCoentsView();
  FAllowItemChildClick := True;
  FDivider := CDefaultDividerColor;
  FScrollbarWidth := 0;
  FDividerHeight := -1;
  FLocalDividerHeight := -1;
  SetLength(FItemsPoints, 0);
  ScrollBars := TViewScroll.Vertical;
  DisableFocusEffect := True;
  AutoCapture := True;
  ClipChildren := True;
  with Background.ItemPressed do begin
    Color := CDefaultBKPressedColor;
    Kind := TViewBrushKind.Solid; 
  end;
  HitTest := True;
end;

procedure TListViewEx.CreateCoentsView;
begin
  FContentViews := TListViewContent.Create(Self);
  FContentViews.Visible := True;
  FContentViews.Stored := False;
  FContentViews.Locked := True;
  FContentViews.Parent := Self;
  FContentViews.ListView := Self;
  FContentViews.WidthSize := TViewSize.FillParent;
  FContentViews.HeightSize := TViewSize.FillParent;
  if csDesigning in ComponentState then begin
    FContentViews.Align := TAlignLayout.Client;
  end else
    RealignContent;
end;

function TListViewEx.CreateScroll: TScrollBar;
begin
  {$IFDEF MSWINDOWS}
  Result := TScrollBar.Create(Self);
  {$ELSE}
  Result := TSmallScrollBar.Create(Self);
  {$ENDIF}
  if FScrollbarWidth > 0 then begin
    SetRttiValue(Result, 'MinClipWidth', FScrollbarWidth);
    SetRttiValue(Result, 'MinClipHeight', FScrollbarWidth);
  end;
end;

destructor TListViewEx.Destroy;
begin
  FAdapter := nil;
  inherited Destroy;
end;

procedure TListViewEx.DoChangeSize(var ANewWidth, ANewHeight: Single);
begin
  inherited DoChangeSize(ANewWidth, ANewHeight);
end;

procedure TListViewEx.DoColumnCountChange(const AColumnCount: Integer);
begin
  FContentViews.FLastColumnCount := AColumnCount;
  FContentViews.FFirstRowIndex := -1;
  FContentViews.FLastRowIndex := -1;
  FContentViews.FLastPosition := 0;
  NotifyDataChanged;
end;

procedure TListViewEx.DoDrawBackground(var R: TRectF);
begin
  if Assigned(FOnDrawViewBackgroud) then
    FOnDrawViewBackgroud(Self, Canvas, R, DrawState);
end;

procedure TListViewEx.DoInVisibleChange;
begin
  inherited DoInVisibleChange;
  FContentViews.InVisible := InVisible;
end;

procedure TListViewEx.DoPaintBackground(var R: TRectF);
begin
  R := RectF(R.Left + Padding.Left, R.Top + Padding.Top,
    R.Right - Padding.Right, R.Bottom - Padding.Bottom);
end;

procedure TListViewEx.DoPullLoad(Sender: TObject);
begin
  FContentViews.FFooter.DoUpdateState(TListViewState.PullUpFinish, 0);
  FContentViews.FState := TListViewState.PullUpFinish;
  if Assigned(FOnPullLoad) then
    FOnPullLoad(Self);
end;

procedure TListViewEx.DoRealign;
var
  LDisablePaint: Boolean;
  W: Single;
  I: Integer;
begin
  if FDisableAlign or IsUpdating then
    Exit;
  if (csDestroying in ComponentState) then
    Exit;
  LDisablePaint := FDisablePaint;
  try
    FDisablePaint := True;

    if csDesigning in ComponentState then begin
      inherited DoRealign;
      Exit;
    end;

    {$IFDEF MSWINDOWS}
    if Assigned(FScroll) and (FScroll.Visible) then
      W := Width - Padding.Right - Padding.Left{$IFDEF MSWINDOWS} - FScroll.Width{$ENDIF}
    else
      W := Width - Padding.Right - Padding.Left;
    {$ELSE}
    W := Width - Padding.Right - Padding.Left;
    {$ENDIF}

    FContentViews.SetBounds(Padding.Left, Padding.Top, W,
      Height - Padding.Bottom - Padding.Top);

    inherited DoRealign;
    
    // �̶��п�
    if FContentViews.FColumnWidth > 0 then begin  
      I := AbsoluteColumnCount;
      if I <> FContentViews.FLastColumnCount then
        DoColumnCountChange(I);
    end;

    if (HeightSize = TViewSize.WrapContent) and (Height > FContentViews.Height) then begin
      FDisableAlign := True;
      BeginUpdate;
      SetSize(Width, FContentViews.Height + Padding.Top + Padding.Bottom);
      EndUpdate;
      FDisableAlign := False;
    end;

  finally
    FDisablePaint := LDisablePaint;
    FContentViews.Invalidate;
  end;
end;

procedure TListViewEx.DoScrollVisibleChange;
begin
  inherited DoScrollVisibleChange;
end;

function TListViewEx.GetAbsoluteColumnCount: Integer;
begin
  Result := FContentViews.GetAbsoluteColumnCount;
end;

function TListViewEx.GetAbsoluteColumnWidth: Single;
begin
  Result := FContentViews.GetAbsoluteColumnWidth;
end;

function TListViewEx.GetColumnCount: Integer;
begin
  Result := FContentViews.FColumnCount;
end;

function TListViewEx.GetColumnDivider: Boolean;
begin
  Result := FContentViews.FColumnDivider;
end;

function TListViewEx.GetColumnWidth: Single;
begin
  Result := FContentViews.FColumnWidth;
end;

function TListViewEx.GetCount: Integer;
begin
  Result := FCount;
end;

function TListViewEx.GetDividerHeight: Single;
begin
  if FLocalDividerHeight = -1 then
    FLocalDividerHeight := InnerCalcDividerHeight;
  Result := FLocalDividerHeight;
end;

function TListViewEx.GetRealDrawState: TViewState;
begin
  Result := TViewState.None;
end;

function TListViewEx.GetRowCount: Integer;
var
  LColumnCount: Integer;
begin
  Result := Length(FItemsPoints);
  LColumnCount := FContentViews.AbsoluteColumnCount;
  if LColumnCount > 1 then begin
    if Result mod LColumnCount > 0 then
      Result := Result div LColumnCount + 1
    else
      Result := Result div LColumnCount;
  end;
end;

function TListViewEx.GetFirstRowIndex: Integer;
begin
  Result := FContentViews.FirstRowIndex;
end;

function TListViewEx.GetFooter: IListViewHeader;
begin
  Result := FContentViews.FFooter;
end;

function TListViewEx.GetHeader: IListViewHeader;
begin
  Result := FContentViews.FHeader;
end;

function TListViewEx.GetItemPosition(Index: Integer): TListItemPoint;
begin
  Result := FItemsPoints[Index];
end;

function TListViewEx.GetItemViews(Index: Integer): TControl;
begin
  Result := FContentViews.FViews.Items[Index];
end;

function TListViewEx.GetLastRowIndex: Integer;
begin
  Result := FContentViews.LastRowIndex;
end;

function TListViewEx.GetVisibleRowCount: Integer;
begin
  Result := FContentViews.VisibleRowCount;
end;

procedure TListViewEx.HScrollChange(Sender: TObject);
begin
  inherited HScrollChange(Sender);
  if Assigned(FContentViews) then
    FContentViews.Realign;
end;

function TListViewEx.InnerCalcDividerHeight: Single;
var
  PPI: Single;
begin
  if (FDividerHeight = -1) and (Assigned(Canvas)) then begin
    PPI := Canvas.Scale;
    if PPI > TEpsilon.Scale then
      Result := 1 / PPI
    else
      Result := 1;

    if PPI >= 2 then
      Result := Result * 2;
  end else
    Result := FDividerHeight;
end;

procedure TListViewEx.InvalidateContentSize;
var
  ItemDefaultHeight: Single;
begin
  SetLength(FItemsPoints, Count);
  FContentBounds^ := TRectD.Empty;
  if Length(FItemsPoints) = 0 then
    Exit;
  ItemDefaultHeight := FAdapter.ItemDefaultHeight;
  FContentBounds.Right := FContentViews.Width;
  FContentBounds.Bottom := (ItemDefaultHeight + GetDividerHeight) * RowCount;

  // �����Զ��帽��ͷ��
  if Assigned(FContentViews.FHeaderView) then
    FContentBounds.Bottom := FContentBounds.Bottom + FContentViews.FHeaderView.Height;

  // �����Զ��帽�ӵײ�
  if Assigned(FContentViews.FFooterView) then
    FContentBounds.Bottom := FContentBounds.Bottom + FContentViews.FFooterView.Height;

  // ����ͷ���߶�
  if (FEnablePullRefresh) and Assigned(FContentViews)
    and (FContentViews.FState = TListViewState.PullDownFinish)
  then
    FContentBounds.Bottom := FContentBounds.Bottom + (FContentViews.FHeader as TControl).Height;
  // ���ϵײ��߶�
  if (FEnablePullLoad) and Assigned(FContentViews.FFooter)
    // and (FContentViews.FState <> TListViewState.PullUpComplete)
  then
    FContentBounds.Bottom := FContentBounds.Bottom + (FContentViews.FFooter as TControl).Height;
end;

function TListViewEx.IsEmpty: Boolean;
begin
  Result := GetCount = 0;
end;

function TListViewEx.IsEnabled(const Index: Integer): Boolean;
begin
  if Assigned(FAdapter) then
    Result := FAdapter.IsEnabled(Index)
  else
    Result := False;
end;

function TListViewEx.IsStoredColumnWidth: Boolean;
begin
  Result := ColumnWidth > 0;
end;

function TListViewEx.IsStoredDividerHeight: Boolean;
begin
  Result := FDividerHeight <> -1;
end;

function TListViewEx.IsStoredScrollbarWidth: Boolean;
begin
  Result := FScrollbarWidth > 0;
end;

procedure TListViewEx.Loaded;
begin
  inherited Loaded;
end;

procedure TListViewEx.NotifyDataChanged;
var
  Offset: Double;
begin
  if (csLoading in ComponentState) or (csDestroying in ComponentState) or FContentViews.FDisableAlign then
    Exit;
  FContentViews.FDisableAlign := True;
  try
    if Assigned(FAdapter) then
      FCount := FAdapter.Count
    else
      FCount := 0;
    FContentViews.HideViews;
    FContentViews.FOffset := -1;
    FContentViews.FLastOffset := -1;
    FContentViews.FLastH := 0;

    if Length(FItemsPoints) > 0 then
      FillChar(FItemsPoints[0], SizeOf(TListItemPoint) * Length(FItemsPoints), 0);

    InvalidateContentSize;

    // �ָ�λ��
    if (FContentViews.FFirstRowIndex > -1) then begin
      if FContentViews.FFirstRowIndex > High(FItemsPoints) then
        FContentViews.FFirstRowIndex := High(FItemsPoints);
      Offset := FScroll.ValueD - FContentViews.FLastPosition;
      FScroll.ValueD := (FAdapter.ItemDefaultHeight + GetDividerHeight) * FContentViews.FFirstRowIndex + Offset;
      FContentViews.FLastPosition := FScroll.ValueD - Offset;
    end;

    DoUpdateScrollingLimits(True);
  finally
    FContentViews.FCount := FCount;
    FContentViews.FDisableAlign := False;
    FContentViews.Realign;
  end;

//  // ���������������, �򽫹�������Ϊ��ײ������������б���
//  Offset := FContentViews.FLastPosition - FScroll.Value;
//  if Offset > 0 then begin
//    FContentViews.FDisableAlign := True;
//    try
//      FContentViews.HideViews;
//      FContentViews.FOffset := -1;
//      FContentViews.FFirstRowIndex := -1;
//      FContentViews.FLastPosition := 0;
//      FContentViews.FLastH := 0;
//      ViewportPosition := PointF(0, FContentBounds.Bottom - FScroll.ViewportSize);
//    finally
//      FContentViews.FDisableAlign := False;
//      FContentViews.Realign;
//    end;
//  end;
  Resize;
end;

procedure TListViewEx.PaintBackground;
var
  R: TRectF;
begin
  R := RectF(0, 0, Width, Height);
  if Assigned(FOnDrawViewBackgroud) then
    DoDrawBackground(R)
  else
    inherited PaintBackground;
  DoPaintBackground(R);
end;

procedure TListViewEx.PullLoadComplete;
begin
  if Assigned(FContentViews) and (FContentViews.FState = TListViewState.PullUpFinish) then
    FContentViews.DoPullLoadComplete;
end;

procedure TListViewEx.PullRefreshComplete;
begin
  if Assigned(FContentViews) and (FContentViews.FState = TListViewState.PullDownFinish) then
    FContentViews.DoPullRefreshComplete;
end;

procedure TListViewEx.RemoveFooterView;
begin
  FContentViews.RemoveFooterView;
end;

procedure TListViewEx.RemoveHeaderView;
begin
  FContentViews.RemoveHeaderView;
end;

procedure TListViewEx.Resize;
begin
  if FResizeing or
    (csLoading in ComponentState) or
    (csDestroying in ComponentState) or
    (csDesigning in ComponentState) then
    Exit;
  FResizeing := True;

  // ����б�߶�Ϊ�Զ���Сʱ������һ�¸�����ͼ�����߶ȣ����Զ�������Сʱ��ʹ��
  if HeightSize = TViewSize.WrapContent then
    FContentViews.FMaxParentHeight := GetParentMaxHeight
  else
    FContentViews.FMaxParentHeight := 0;

  inherited Resize;

  if Assigned(FAdapter) then begin
    UpdateScrollBar;
    FContentViews.DoRealign;
    FLastHeight := Height;
    FLastWidth := Width;
  end;

  FResizeing := False;
end;

procedure TListViewEx.SetAdapter(const Value: IListAdapter);
begin
  if FAdapter <> Value then begin
    FAdapter := Value;
    FContentViews.FAdapter := Value;
    FContentViews.FFirstRowIndex := -1;
    FContentViews.FLastRowIndex := -1;
    FContentViews.FLastPosition := 0;
    if FAdapter is TListAdapterBase then
      (FAdapter as TListAdapterBase).FListView := Self;
    NotifyDataChanged;
    HandleSizeChanged;
  end;
end;

procedure TListViewEx.SetColumnCount(const Value: Integer);
begin
  if FContentViews.FColumnCount <> Value then begin
    FContentViews.FColumnCount := Value;
    DoColumnCountChange(AbsoluteColumnCount);
    Invalidate;
  end;
end;

procedure TListViewEx.SetColumnDivider(const Value: Boolean);
begin
  if FContentViews.FColumnDivider <> Value then begin
    FContentViews.FColumnDivider := Value;
    Invalidate;
  end;
end;

procedure TListViewEx.SetColumnWidth(const Value: Single);
begin
  if FContentViews.FColumnWidth <> Value then begin
    FContentViews.FColumnWidth := Value;
    DoColumnCountChange(AbsoluteColumnCount);
    Invalidate;
  end;
end;

procedure TListViewEx.SetDivider(const Value: TAlphaColor);
begin
  if FDivider <> Value then begin
    FDivider := Value;
    Invalidate;
  end;
end;

procedure TListViewEx.SetDividerHeight(const Value: Single);
begin
  if FDividerHeight <> Value then begin
    FDividerHeight := Value;
    if not (csLoading in ComponentState) then begin     
      FLocalDividerHeight := FDividerHeight;
      RealignContent;
      Invalidate;
    end;
  end;
end;

procedure TListViewEx.SetEnablePullLoad(const Value: Boolean);
begin
  if FEnablePullLoad <> Value then begin
    FEnablePullLoad := Value;
    if Assigned(FContentViews) then begin
      if (not Value) then begin
        if csDesigning in ComponentState then
          FContentViews.FreeFooter
        else
          FContentViews.DoPullLoadComplete;
      end else begin
        FContentViews.InitFooter;
        if Assigned(FContentViews.FFooter) then begin
          FContentBounds.Bottom := FContentBounds.Bottom + (FContentViews.FFooter as TControl).Height;
          DoUpdateScrollingLimits(True);
        end;
        FContentViews.FLastOffset := -1;
        DoRealign;
      end;
    end;
  end;
end;

procedure TListViewEx.SetEnablePullRefresh(const Value: Boolean);
begin
  if FEnablePullRefresh <> Value then begin
    FEnablePullRefresh := Value;
    if Assigned(FContentViews) then begin
      if (not Value) then begin
        if csDesigning in ComponentState then
          FContentViews.FreeHeader
        else
          FContentViews.DoPullRefreshComplete;
      end else
        FContentViews.InitHeader;
    end;
  end;
end;

procedure TListViewEx.SetScrollbarWidth(const Value: Single);
begin
  if FScrollbarWidth <> Value then begin
    FScrollbarWidth := Value;
    FreeAndNil(FScroll);
    InitScrollbar;
    if Assigned(FScroll) then
      UpdateScrollBar;
  end;
end;

procedure TListViewEx.VScrollChange(Sender: TObject);
begin
  if FScrolling then Exit;  
  inherited VScrollChange(Sender);
  if Assigned(FContentViews) then
    FContentViews.Realign;
end;

{ TListViewContent }

procedure TListViewContent.AddControlToCacle(const ItemType: Integer;
  const Value: TViewBase);
var
  List: TListViewList;
begin
  if not FCacleViews.ContainsKey(Itemtype) then begin
    List := TListViewList.Create;
    FCacleViews.Add(ItemType, List);
  end else begin
    List := FCacleViews[ItemType];
  end;
  Value.Visible := False;
  Value.OnClick := nil;
  List.Add(Value)
end;

procedure TListViewContent.AddHeaderView(const View: TControl);
begin
  if not Assigned(View) then Exit;
  if Assigned(FHeaderView) then begin
    RemoveObject(FHeaderView);
    FHeaderView := nil;
  end;
  View.Name := '';
  View.Parent := Self;
  View.Stored := False;
  View.Index := 0;
  View.Visible := False;
  FHeaderView := View;
end;

procedure TListViewContent.AddFooterView(const View: TControl);
begin
  if not Assigned(View) then Exit;
  if Assigned(FFooterView) then begin
    RemoveObject(FFooterView);
    FHeaderView := nil;
  end;
  View.Name := '';
  View.Parent := Self;
  View.Stored := False;
  View.Visible := False;
  FFooterView := View;
end;

function TListViewContent.AddFooterView(const View: TViewClass): TControl;
begin
  if not Assigned(View) then
    Result := nil
  else begin
    Result := View.Create(Self);
    AddFooterView(Result);
  end;
end;

function TListViewContent.AddHeaderView(const View: TViewClass): TControl;
begin
  if not Assigned(View) then
    Result := nil
  else begin
    Result := View.Create(Self);
    AddHeaderView(Result);
  end;
end;

procedure TListViewContent.AfterPaint;
begin
  inherited AfterPaint;
  // ��������չЧ��
  if Assigned(ListView) and ListView.NeedPaintScrollingStretchGlow then
    ListView.PaintScrollingStretchGlow(Canvas, Width, Height,
      ListView.FScrollStretchStrength, GetAbsoluteOpacity);
end;

procedure TListViewContent.ClearViews;
var
  Item: TPair<Integer, TListViewList>;
  ItemView: TPair<Integer, TViewBase>;
  I: Integer;
begin
  for Item in FCacleViews do begin
    for I := 0 to Item.Value.Count - 1 do
      RemoveObject(Item.Value.Items[I]);
    Item.Value.DisposeOf;
  end;
  FCacleViews.Clear;
  FItemViews.Clear;
  for ItemView in FViews do
    RemoveObject(ItemView.Value);
  FViews.Clear;
end;

constructor TListViewContent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FIsDesigning := csDesigning in ComponentState;
  FViews := TDictionary<Integer, TViewBase>.Create(256);
  FCacleViews := TDictionary<Integer, TListViewList>.Create(17);
  FItemViews := TDictionary<Pointer, Integer>.Create(256);
  FItemClick := TDictionary<Pointer, TNotifyEvent>.Create(256);
  FFirstRowIndex := -1;
  FLastRowIndex := -1;
  
  FLastPosition := 0;

  FColumnCount := 1;
  FColumnWidth := -1;
  FColumnDivider := True;
  FLastColumnCount := AbsoluteColumnCount;

  FDividerBrush := TBrush.Create(TBrushKind.Solid, TAlphaColorRec.Null);

  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := 10;
  FTimer.OnTimer := DoTimer;
end;

destructor TListViewContent.Destroy;
begin
  ClearViews;
  FreeAndNil(FViews);
  FreeAndNil(FCacleViews);
  FreeAndNil(FDividerBrush);
  FreeAndNil(FItemViews);
  FreeAndNil(FItemClick);
  FreeHeader;
  FreeFooter;
  if Assigned(FTimer) then begin
    RemoveObject(FTimer);
    FTimer := nil;
  end;
  if Assigned(FHeaderView) then begin
    RemoveObject(FHeaderView);
    FHeaderView := nil;
  end;
  if Assigned(FFooterView) then begin
    RemoveObject(FFooterView);
    FFooterView := nil;
  end;
  inherited;
end;

procedure TListViewContent.DoChangeSize(var ANewWidth, ANewHeight: Single);
begin
  inherited DoChangeSize(ANewWidth, ANewHeight);
end;

procedure TListViewContent.DoFooterClick(Sender: TObject);
begin
  if ListView.FEnablePullLoad then begin
    if FState in [TListViewState.None, TListViewState.PullUpStart, TListViewState.PullUpOK] then
      ListView.DoPullLoad(Self);
  end;
end;

procedure TListViewContent.DoItemChildClick(Sender: TObject);
begin
  if (FItemViews.ContainsKey(Sender)) then begin
    if FItemClick.ContainsKey(Sender) and Assigned(FItemClick[Sender]) then
      FItemClick[Sender](Sender);
    if Assigned(ListView.FOnItemClickEx) then
      ListView.FOnItemClickEx(ListView, FItemViews[Sender], TControl(Sender));
  end;
end;

procedure TListViewContent.DoItemClick(Sender: TObject);
begin
  if (FItemViews.ContainsKey(Sender)) then begin
    if FItemClick.ContainsKey(Sender) and Assigned(FItemClick[Sender]) then
      FItemClick[Sender](Sender);
    if Assigned(ListView.FOnItemClick) then
      ListView.FOnItemClick(ListView, FItemViews[Sender], TView(Sender));
  end;
end;

procedure TListViewContent.DoMouseDownFrame(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
    Repaint;
end;

procedure TListViewContent.DoPaintFrame(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  if TControl(Sender).Pressed then begin
    Canvas.FillRect(ARect, 0, 0, [], Opacity, ListView.Background.ItemPressed);
  end;
end;

procedure TListViewContent.DoPullLoadComplete;
begin
  if Assigned(FFooter) then begin
    if FState = TListViewState.PullUpComplete then
      Exit;
    FFooter.DoUpdateState(TListViewState.PullUpComplete, 0);
    if FIsDesigning then begin
      RemoveObject(FFooter as TControl);
      FFooter := nil;
      FState := TListViewState.None;
      Exit;
    end;
    FCompleteTime := GetTimestamp;
    if Assigned(FTimer) then begin
      FState := TListViewState.PullUpComplete;
      FTimer.Enabled := True;
    end;
  end;
end;

procedure TListViewContent.DoPullRefreshComplete;
begin
  if Assigned(FHeader) then begin
    if FState = TListViewState.PullDownComplete then
      Exit;
    FHeader.DoUpdateState(TListViewState.PullDownComplete, 0);
    if FIsDesigning then begin
      RemoveObject(FFooter as TControl);
      FHeader := nil;
      FState := TListViewState.None;
      Exit;
    end;
    FCompleteTime := GetTimestamp;
    if Assigned(FTimer) then begin
      FState := TListViewState.PullDownComplete;
      FTimer.Enabled := True;
    end;
  end;  
end;

procedure TListViewContent.DoRealign;

  // �ݹ����������������ĵ���¼�
  procedure SetChildClickEvent(const Parent: TControl; const Index: Integer);
  var
    I: Integer;
    Control: TControl;
  begin
    for I := 0 to Parent.ControlsCount - 1 do begin
      Control := Parent.Controls[I];
      if not Control.Visible then
        Continue;
      if Control.HitTest then begin
        Control.OnClick := DoItemChildClick;
        FItemViews.AddOrSetValue(Control, Index);
      end;
      if Control.ControlsCount > 0 then
        SetChildClickEvent(Control, Index);
    end;
  end;


  // �ݹ����������������ĵ���¼�����Ӧ��������
  procedure UpdateChildEventIndex(const Parent: TControl; const Index: Integer);
  var
    I: Integer;
    Control: TControl;
  begin
    for I := 0 to Parent.ControlsCount - 1 do begin
      Control := Parent.Controls[I];
      if not Control.Visible then
        Continue;
      if Control.HitTest then
        FItemViews.AddOrSetValue(Control, Index);
      if Control.ControlsCount > 0 then
        SetChildClickEvent(Control, Index);
    end;
  end;

  // ��ȡ View
  function GetView(const ItemView: TViewBase): TView;
  begin
    if ItemView is TView then begin
      Result := ItemView as TView;
    end else if (TControl(ItemView) is TFrame) and (ItemView.ControlsCount = 1) and (ItemView.Controls[0] is TView) then
      Result := TView(ItemView.Controls[0]) // ����� Frame ����ֻ��һ��TView�����
    else
      Result := nil;
  end;

  // �Ƴ��б���, �黹��������
  procedure RemoveItemView(const I: Integer; const ItemView: TViewBase);
  begin
    FViews.Remove(I);
    AddControlToCacle(FAdapter.GetItemViewType(I), ItemView);
  end;

  function EqulsMethod(const A, B: TNotifyEvent): Boolean;
  begin
    Result := TMethod(A) = TMethod(B);
  end;

var
  First, Last: Double;
  ItemDefaultHeight, Offset, LV, V, AdjustH, H, MH, LMH: Double;
  AH, AW, AL, MinH, MaxH: Single;
  I, J, S, K, ItemType, LColumnCount: Integer;
  Item: PListItemPoint;
  Control, ItemView: TViewBase;
  View: TView;
  DividerHeight: Double;
  IsMoveDown, LCheckViews: Boolean;
  FOnItemMeasureHeight: TOnItemMeasureHeight;
  FNewOnClick: TNotifyEvent;
  LDisablePaint: Boolean;
  Ctrl: TControl;
begin
  if FIsDesigning then begin
    inherited DoRealign;
    Exit;
  end;
  if FDisableAlign or (FAdapter = nil) or (not Assigned(Canvas))or
    (csLoading in ComponentState) or
    (csDestroying in ComponentState) then
    Exit;
  if (FCount = 0) then begin
    if Assigned(FFooter) then
      (FFooter as TControl).Visible := False;
    Exit;
  end;
  LDisablePaint := FDisablePaint;
  FDisableAlign := True;
  FDisablePaint := True;

  // ƫ��λ�� (������λ��)
  Offset := ListView.VScrollBarValue;
  // ���ݹ�����ƫ��ֵ���ж��Ƿ��б仯
  AdjustH := Offset - FOffset;
  FOffset := Offset;

  // ��ǰ������
  LColumnCount := FLastColumnCount;

  if (LColumnCount > 1) or (FColumnWidth > 0) then begin
    // ���л�̶��п�ʱ
    AW := GetAbsoluteColumnWidth;
    // ��¼��ǰ����ʱ���п�
    FLastColumnWidth := AW;
  end else
    AW := FSize.Width;
  AH := FSize.Height;

  // ��ȡ��߶ȡ����������ޱ仯��������
  if (FLastW = AW) and (FLastH = AH) and (FLastOffset = Offset) then begin
    FDisableAlign := False;
    FDisablePaint := LDisablePaint;
    Exit;
  end else begin
    FLastW := AW;
    FlastH := AH;
    FLastOffset := Offset;
  end;

  {$IFDEF MSWINDOWS}
  {$IFDEF DEBUG}
  //OutputDebugString('TListViewContent.DoRealign');
  {$ENDIF}
  {$ENDIF}

  if (Abs(AdjustH) > Height * 2) then begin
    HideViews;
    LCheckViews := False;
  end else
    LCheckViews := FViews.Count > 0;

  // Ĭ���и�
  ItemDefaultHeight := FAdapter.ItemDefaultHeight;
  // �������ǰ����ʾ�ĵ�һ��λ�ú����һ��λ��
  First := Offset;
  // �����Ҫ�Զ�������С���ҹ�����ƫ��Ϊ0ʱ��˵�����ڳ�ʼ���б�
  if (FMaxParentHeight > 0) and (Offset = 0) then
    Last := Offset + FMaxParentHeight // ʹ�ø�����ͼ�����߶�Ϊ�б���ĵױ�
  else
    Last := Offset + AH; // ListView.FContentBounds.Height;
  // �ָ����߶�
  DividerHeight := ListView.GetDividerHeight;

  // ������ʼ��
  J := 0;
  K := FFirstRowIndex + FViews.Count;
  IsMoveDown := AdjustH >= 0;  // ��ǰ�Ƿ����¹���
  FOnItemMeasureHeight := ListView.FOnItemMeasureHeight;
  AdjustH := 0;
  AL := 0;
  MH := 0;
  LMH := 0;

  BeginUpdate;
  try
    // ���ݼ�¼��״̬�������������ʾλ��, ����ÿ�ζ���ͷ��ʼ��λ��
    if IsMoveDown then begin
      // ���¹���ʱ��ֱ�ӴӼ�¼�Ŀ�ʼλ�ÿ�ʼ��
      if FFirstRowIndex <= 0 then begin
        S := 0;
        V := 0;
      end else begin
        S := FFirstRowIndex;
        V := FLastPosition;
      end;
    end else begin
      // ���Ϲ���ʱ���������ʼλ��
      V := FLastPosition;
      S := FFirstRowIndex;
      H := 0;
      while (S > 0) do begin
        if V <= First then
          Break;
        Dec(S);
        if LColumnCount <= 1 then begin
          H := ListView.FItemsPoints[S].H;
          if H < 0 then
            Continue;
          if H = 0 then
            V := V - ItemDefaultHeight - DividerHeight
          else
            V := V - H - DividerHeight;
        end else begin
          if S mod LColumnCount = 0 then begin
            if H < 0 then
              Continue;
            if H = 0 then
              V := V - ItemDefaultHeight - DividerHeight
            else
              V := V - H - DividerHeight;
            H := 0;
          end else begin
            if ListView.FItemsPoints[S].H > H then
              H := ListView.FItemsPoints[S].H;
          end;
        end;
      end;
      if S <= 0 then begin
        S := 0;
        V := 0;
      end;
    end;

    FFirstRowIndex := -1;
    FLastRowIndex := -1;
    V := V - FPullOffset;
    FPullOffset := 0;

    // ���� Header λ�ú�״̬
    if ListView.FEnablePullRefresh and Assigned(FHeader) and (S = 0) then begin
      Ctrl := FHeader as TControl;
      H := Ctrl.Height;
      LV := -H - Offset;

      if FState = TListViewState.PullDownFinish then begin    
        Ctrl.SetBounds(AL, V - Offset, FSize.Width, H);
        V := V + H;
        FPullOffset := H;
      end else begin
        Ctrl.SetBounds(AL, -H - Offset, FSize.Width, H);
     
        if Offset < 0 then begin
          case FState of
            TListViewState.None: 
              begin
                FHeader.DoUpdateState(TListViewState.PullDownStart, Offset);
                FState := TListViewState.PullDownStart;
              end;
            TListViewState.PullDownStart: 
              begin
                if (Offset < 0) and (LV >= 0) then begin
                  FHeader.DoUpdateState(TListViewState.PullDownOK, Offset);
                  FState := TListViewState.PullDownOK;
                end;
              end;
            TListViewState.PullDownOK: 
              begin
                if (LV < 0) then begin
                  FHeader.DoUpdateState(TListViewState.PullDownStart, Offset);  
                  FState := TListViewState.PullDownStart;
                end;
              end;
          end;
        end else begin
          if FState = TListViewState.PullDownStart then
            FState := TListViewState.None;
        end;    
      end;
    end else if Assigned(FHeader) then
      (FHeader as TControl).Visible := False;

    // �Զ��帽��ͷ��
    if Assigned(FHeaderView) and (S = 0) then begin
      Ctrl := FHeaderView;
      H := Ctrl.Height;
      Ctrl.Visible := V - Offset + H > 0;
      Ctrl.SetBounds(AL, V - Offset, FSize.Width, H);
      V := V + H + DividerHeight;
    end else if Assigned(FHeaderView) then
      FHeaderView.Visible := False;

    LV := V;

    // ��ָ��λ�ÿ�ʼ�����ɲ������б���
    for I := S to High(ListView.FItemsPoints) do begin
      if I < 0 then
        Continue;
      Item := @ListView.FItemsPoints[I];

      // ��������0ʱ������ʱ��AL�����0
      if (LColumnCount > 1) then begin
        if (I mod LColumnCount = 0) then begin
          AL := 0;
          // �������һ���λ��
          if J > 0 then begin
            V := V + MH + DividerHeight;
          end;
          // �߶ȱ仯ʱ�����µ�����С
          if MH <> LMH then begin
            if MH <= 0 then 
              AdjustH := AdjustH - LMH
            else 
              AdjustH := AdjustH + (MH - LMH)
          end;
          MH := 0; 
          LMH := 0;
        end else
          AL := AL + DividerHeight + AW;
      end;


      // ��ȡ�б���߶�
      H := Item.H;
      if H = 0 then
        H := ItemDefaultHeight
      else if H < 0 then
        Continue;

      // ��¼���߶�
      if (LColumnCount > 1) then
        LMH := Max(LMH, H)
      else
        LMH := H;

      // �ж��б������״̬
      if AL = 0 then begin
        if (V + LMH + DividerHeight <= First) then begin
          // ����������������
          // ����Ѿ���ʾ������ɾ��
          if LCheckViews and FViews.ContainsKey(I) then
            RemoveItemView(I, FViews[I]);
          // �������һ���λ��
          if LColumnCount = 1 then
            V := V + LMH + DividerHeight;
          Continue;
        end else if V >= Last then begin
          // ����β����������
          S := I;
          while S < K do begin
            if FViews.ContainsKey(S) then
              RemoveItemView(S, FViews[S]);
            Inc(S);
          end;
          Break;
        end;

        // ����ǵ�һ��������, ��¼״̬
        if FFirstRowIndex = -1 then begin
          FFirstRowIndex := I;
          FLastPosition := V;
          if I = 0 then
            Last := Last + Height - V;
        end;

        // ��¼�б���Ŀ�ʼλ��
        LV := V;
      end;

      // �����������������
      Inc(J);

      // ����Ѿ����ڣ�˵��֮ǰ���ع�������������ʾ�����Ѿ�������λ��
      if FViews.ContainsKey(I) then begin

        AH := H;
        // ��ȡһ���б�����ͼ
        ItemView := FViews[I];

        // �������nil, �׳�����
        if not Assigned(ItemView) then
          raise Exception.Create('View is null.');

        // �����û��޸��иߵ��¼�
        FAdapter.ItemMeasureHeight(I, AH);
        if Assigned(FOnItemMeasureHeight) then
          FOnItemMeasureHeight(ListView, I, AH);

        // ����и߸����ˣ��������Ҫ�����������Ĵ�С�������¼һ�±仯��С
        if LColumnCount <= 1 then begin
          if Item.H <> AH then begin
            if AH <= 0 then begin
              AdjustH := AdjustH - H
            end else begin
              AdjustH := AdjustH + (AH - H)
            end;
            Item.H := AH;
          end;
        end else begin
          MH := Max(MH, AH);
          Item.H := AH;
        end;

        // ���� V, �����б���ĵײ�λ��
        if LColumnCount > 1 then begin
          if AH <= 0 then begin
            // �Ƴ�
            RemoveItemView(I, ItemView);
            Continue;
          end;
        end else begin
          if AH > 0 then begin
            V := V + AH + DividerHeight
          end else begin
            // �Ƴ�
            RemoveItemView(I, ItemView);
            Continue;
          end;
        end;

      end else begin
        // ���������
        // �ڻ�����ͼ�б���ȡһ���������ͼ
        ItemType := FAdapter.GetItemViewType(I);
        Control := GetControlFormCacle(ItemType);

        // ��ȡһ���б�����ͼ
        ItemView := FAdapter.GetView(I, Control, Self);

        // �������nil, �׳�����
        if not Assigned(ItemView) then
          Continue;

        // ��¼�������б���
        FViews.AddOrSetValue(I, ItemView);

        // ��ȡ View
        View := GetView(ItemView);

        // �����ǰ���뻺���ͬ��˵���������ɵ�, ��ʼ��һЩ����
        if Control <> ItemView then begin
          {$IFDEF Debug}
          {$IFDEF MSWINDOWS}
          OutputDebugString(PChar(Format('�����б���ͼ Index: %d, %s. (ViewCount: %d)',
            [I, ItemView.ClassName, FViews.Count])));
          {$ENDIF}
          {$IFDEF ANDROID}
          //LogD(Format('�����б���ͼ Index: %d (ViewCount: %d)', [I, FViews.Count]));
          {$ENDIF}
          {$ENDIF}

          ItemView.Name := '';
          ItemView.Parent := Self;

          if Assigned(View) then begin
            // ����� TView �� ���ð���ʱ�ı�����ɫ
            if ItemView <> View then
              ItemView.HitTest := False;
            View.Background.ItemPressed.Assign(ListView.Background.ItemPressed);
            View.HitTest := True;
            if ListView.FAllowItemChildClick then
              SetChildClickEvent(View, I);
          end else begin
            // �����һ�� Frame���������Ե��
            // ���õ���¼���������尴�º��ɿ��¼�ʱ�ػ�
            ItemView.HitTest := True;
            ItemView.OnPainting := DoPaintFrame;
            ItemView.OnMouseDown := DoMouseDownFrame;
            ItemView.OnMouseUp := DoMouseDownFrame;
            if ListView.FAllowItemChildClick then
              SetChildClickEvent(ItemView, I);
          end;
        end else begin
          if ListView.FAllowItemChildClick then
            UpdateChildEventIndex(ItemView, I);
        end;

        // ��¼�б����������ŵĶ�Ӧ��ϵ���¼�����ͼ��Ӧ��ϵ���ֵ���
        FNewOnClick := DoItemClick;
        if Assigned(View) then begin
          if TViewState.Checked in View.ViewState then
            View.ViewState := [TViewState.Checked]
          else
            View.ViewState := [];
          FItemViews.AddOrSetValue(View, I);
          if Assigned(View.OnClick) and (not EqulsMethod(FNewOnClick, View.OnClick)) then
            FItemClick.AddOrSetValue(View, View.OnClick);
          View.OnClick := FNewOnClick;
        end else begin
          FItemViews.AddOrSetValue(ItemView, I);
          if Assigned(ItemView.OnClick) and (not EqulsMethod(FNewOnClick, ItemView.OnClick)) then
            FItemClick.AddOrSetValue(ItemView, ItemView.OnClick);
          ItemView.OnClick := FNewOnClick;
        end;

        // ������С��λ��
        if Assigned(View) then begin
          AH := View.Height;
          MinH := View.MinHeight;
          MaxH := View.MaxHeight;
          if (MaxH > 0) and (AH > MaxH) then AH := MaxH;
          if (MinH > 0) and (AH < MinH) then AH := MinH;
        end else
          AH := ItemView.Height;

        // �����û��޸��иߵ��¼�
        FAdapter.ItemMeasureHeight(I, AH);
        if Assigned(FOnItemMeasureHeight) then
          FOnItemMeasureHeight(ListView, I, AH);

        // ����и߸����ˣ��������Ҫ�����������Ĵ�С�������¼һ�±仯��С
        if LColumnCount <= 1 then begin
          if H <> AH then begin
            if AH <= 0 then begin
              AdjustH := AdjustH - H
            end else begin
              AdjustH := AdjustH + (AH - H)
            end;
            Item.H := AH;
          end;
        end else
          Item.H := AH;

        // ���� V, �����б���ĵײ�λ��
        if LColumnCount > 1 then begin
          if AH <= 0 then begin
            // �Ƴ�
            RemoveItemView(I, ItemView);
            Continue;
          end;
        end else begin
          if AH > 0 then begin
            V := V + AH + DividerHeight
          end else begin
            // �Ƴ�
            RemoveItemView(I, ItemView);
            Continue;
          end;
        end;

        ItemView.Visible := True;

        if Assigned(View) then begin
          TListViewContent(View).FInVisible := ListView.FInVisible;
          if AH <> ItemView.Height then
            TListViewContent(View).HeightSize := TViewSize.CustomSize;
        end;

      end;

      // ���´�С����ʾ����
      ItemView.SetBounds(AL, LV - Offset, AW, AH);

      // �������С������߶Ȼ��ǲ�һ�£���ʹ��ʵ�ʵ���ͼ�߶�
      if ItemView.Height <> AH then begin
        Item.H := ItemView.Height;
        H := Item.H - AH;
        if LColumnCount <= 1 then
          AdjustH := AdjustH + H;
        V := V + H;
      end; 

      MH := Max(MH, AH);

      // ��¼�ײ�λ��
      FViewBottom := V;
    end;

    // ����ʱ����ʣ�µĴ�С�仯
    if (LColumnCount > 1) then begin
      AL := 0;
      if (MH > 0) then begin
        // �������һ���λ��
        if J > 0 then
          V := V + MH + DividerHeight;
        FViewBottom := V;
        // �߶ȱ仯ʱ�����µ�����С
        if (MH <> LMH) then begin
          if MH <= 0 then
            AdjustH := AdjustH - LMH
          else
            AdjustH := AdjustH + (MH - LMH)
        end;
      end;
    end;

    AH := FSize.Height;

    // �Զ��帽��β��
    if Assigned(FFooterView) then begin
      if (FFirstRowIndex + J >= FCount) then begin
        H := FFooterView.Height;
        FFooterView.SetBounds(AL, FViewBottom - Offset, FSize.Width, H);
        FFooterView.Visible := True;
        FViewBottom := FViewBottom + H;
      end else
        FFooterView.Visible := False;
    end;

    // ���� Footer λ�ú�״̬
    if ListView.FEnablePullLoad and Assigned(FFooter) and (FCount > 0) then begin
      Ctrl := FFooter as TControl;

      // �����ʾ�������һ�У�˵���Ѿ������������
      if FFirstRowIndex + J >= FCount then begin
        H := Ctrl.Height;
        Ctrl.SetBounds(AL, FViewBottom - Offset, FSize.Width, H);
        Ctrl.Visible := True;
        Ctrl.HitTest := True;
        Ctrl.OnClick := DoFooterClick;

        case FState of
          TListViewState.None: 
            begin
              FFooter.DoUpdateState(TListViewState.PullUpStart, Offset);
              FState := TListViewState.PullUpStart;
            end;  
          TListViewState.PullUpStart: 
            begin
              if (FViewBottom - Offset + H + 8 <= AH) then begin
                FFooter.DoUpdateState(TListViewState.PullUpOK, Offset);
                FState := TListViewState.PullUpOK;
              end;
            end;
          TListViewState.PullUpOK:
            begin
              if (FViewBottom - Offset + H > AH) then begin
                FFooter.DoUpdateState(TListViewState.PullUpStart, Offset);
                FState := TListViewState.PullUpStart;
              end;
            end;
        end;        
      end else begin
        Ctrl.Visible := False;
        if FState = TListViewState.PullUpStart then
          FState := TListViewState.None; 
      end;
    end else if Assigned(FFooter) then
      (FFooter as TControl).Visible := False;
    
  finally
    // ��ʾ�����һ���б���������
    FLastRowIndex := FFirstRowIndex + J;
    FDisablePaint := LDisablePaint;
    EndUpdate;
    if (FMaxParentHeight > 0) and (FFirstRowIndex = 0) then begin
      // ����Ҫ�Զ�������С��������ʾ������Ϊ��һ��ʱ
      // �����ǰ�б���ͼ�ĵײ�λ��С�ڸ�����С����ʹ�õ�ǰ��ͼ�ײ�Ϊ�б��߶�
      if FViewBottom < FMaxParentHeight then
        SetSize(Width, FViewBottom)
      else // �������ʱ����ʹ�ø������߶�Ϊ�б���ͼ�߶�
        SetSize(Width, FMaxParentHeight)
    end;
    if AdjustH <> 0 then begin
      // �߶ȱ仯��, ���¹�����״̬
      ListView.FContentBounds.Bottom := ListView.FContentBounds.Bottom + AdjustH;
      ListView.DoUpdateScrollingLimits(True);
    end;
    FDisableAlign := False;
  end;
end;

procedure TListViewContent.DoTimer(Sender: TObject);
begin
  if (not Assigned(Self)) or (csDestroying in ComponentState) then
    Exit;
  if Assigned(ListView) then begin
    if GetTimestamp - FCompleteTime < 300 then 
      Exit;
    FTimer.Enabled := False;
    if (FState = TListViewState.PullDownComplete) then begin
      if Assigned(FHeader) then begin
        ListView.FContentBounds.Bottom := ListView.FContentBounds.Bottom - FPullOffset;
        FPullOffset := 0;
        FHeader.DoUpdateState(TListViewState.None, 0);
        if not ListView.FEnablePullRefresh then
          ListView.FContentBounds.Bottom := ListView.FContentBounds.Bottom - (FHeader as TControl).Height;
        ListView.DoUpdateScrollingLimits(True);
      end;
    end;
    if (FState = TListViewState.PullUpComplete) then begin
      if Assigned(FFooter) then begin   
        FFooter.DoUpdateState(TListViewState.None, 0);
        if not ListView.FEnablePullLoad then
          ListView.FContentBounds.Bottom := ListView.FContentBounds.Bottom - (FFooter as TControl).Height;
        ListView.DoUpdateScrollingLimits(True);
      end;
    end;
    FState := TListViewState.None;
    FLastOffset := -1;
    DoRealign;
  end else
    FTimer.Enabled := False;
end;

procedure TListViewContent.DrawDivider(Canvas: TCanvas);
var
  I, J: Integer;
  X, Y, DividerHeight, LY: Double;
begin
  DividerHeight := ListView.GetDividerHeight;
  if (DividerHeight > 0) and (ListView.FDivider and $FF000000 <> 0) then begin
    FDividerBrush.Color := ListView.FDivider;
    Y := FLastPosition - FOffset;
    if FLastColumnCount > 1 then begin
      J := 0;
      X := 0;
      Y := Y - DividerHeight;
      LY := Y;
      // ������
      for I := FirstRowIndex to FLastRowIndex do begin
        if (I mod FLastColumnCount = 0) or (J = 0) then begin
          Y := Y + X;
          Canvas.FillRect(RectF(0, Y, Width, Y + DividerHeight),
            0, 0, [], ListView.Opacity, FDividerBrush);
          Y := Y + DividerHeight;
          X := Max(ListView.FItemsPoints[I].H, X);
          Inc(J);
        end;
      end;
      if (FLastRowIndex mod FLastColumnCount > 0) then begin
        Y := Y + X;
        Canvas.FillRect(RectF(0, Y, Width, Y + DividerHeight),
          0, 0, [], ListView.Opacity, FDividerBrush);
      end;
      // ������
      if FColumnDivider then begin
        if Assigned(FFooterView) and (FFooterView.Visible) then
          Y := FFooterView.Position.Y
        else if Assigned(FFooter) and (FFooter.Visible) then
          Y := TControl(FFooter).Position.Y;
        X := FLastColumnWidth;
        for I := 0 to FLastColumnCount - 1 do begin                    
          Canvas.FillRect(RectF(X, LY, X + DividerHeight, Y),
            0, 0, [], ListView.Opacity, FDividerBrush); 
          X := X + DividerHeight + FLastColumnWidth;
        end;
      end;
    end else begin
      if Assigned(FHeaderView) then begin
        Y := Y - DividerHeight;
        for I := FirstRowIndex to FLastRowIndex do begin
          Canvas.FillRect(RectF(0, Y, Width, Y + DividerHeight),
            0, 0, [], ListView.Opacity, FDividerBrush);
          Y := Y + ListView.FItemsPoints[I].H + DividerHeight;
        end;
      end else begin
        for I := FirstRowIndex to FLastRowIndex do begin
          Y := Y + ListView.FItemsPoints[I].H;
          Canvas.FillRect(RectF(0, Y, Width, Y + DividerHeight),
            0, 0, [], ListView.Opacity, FDividerBrush);
          Y := Y + DividerHeight;
        end;
      end;
    end;
  end;
end;

procedure TListViewContent.FreeFooter;
begin
  if Assigned(FFooter) then begin
    RemoveObject(FFooter as TControl);
    FFooter := nil;
  end;
end;

procedure TListViewContent.FreeHeader;
begin
  if Assigned(FHeader) then begin
    RemoveObject(FHeader as TControl);
    FHeader := nil;
  end;
end;

function TListViewContent.GetAbsoluteColumnCount: Integer;
begin
  if FColumnWidth > 0 then begin
    Result := Trunc((Width + ListView.FDividerHeight) / (FColumnWidth + ListView.FDividerHeight));
    if Result < 1 then Result := 1;    
  end else
    Result := FColumnCount;
end;

function TListViewContent.GetAbsoluteColumnWidth: Single;
begin
  if FColumnWidth > 0 then
    Result := FColumnWidth
  else
    Result := (FSize.Width - (FColumnCount - 1) * ListView.FDividerHeight) / FColumnCount;
end;

function TListViewContent.GetControlFormCacle(const ItemType: Integer): TViewBase;
var
  List: TListViewList;
begin
  if not FCacleViews.ContainsKey(Itemtype) then begin
    List := TListViewList.Create;
    FCacleViews.Add(ItemType, List);
  end else begin
    List := FCacleViews[ItemType];
  end;
  if List.Count > 0 then begin
    Result := List.Last;
    List.Delete(List.Count - 1);
  end else
    Result := nil;
end;

function TListViewContent.GetVisibleRowCount: Integer;
begin
  Result := FLastRowIndex - FFirstRowIndex;
end;

procedure TListViewContent.HideViews;
var
  ItemView: TPair<Integer, TViewBase>;
  ItemViewType: Integer;
begin
  if Assigned(FAdapter) then
    FCount := FAdapter.Count
  else
    FCount := 0;
  for ItemView in FViews do begin
    if ItemView.Key >= FCount then
      RemoveObject(ItemView.Value)
    else begin
      ItemViewType := FAdapter.GetItemViewType(ItemView.Key);
      if ItemViewType = ListViewType_Remove then // �������״̬��ɾ���������
        RemoveObject(ItemView.Value)
      else begin
        AddControlToCacle(ItemViewType, ItemView.Value);
      end;
    end;
  end;
  FViews.Clear;
  if Assigned(FFooter) then
    (FFooter as TControl).Visible := False;
  if Assigned(FFooterView) then
    FFooterView.Visible := False;
end;

procedure TListViewContent.InitFooter;
begin
  if not Assigned(FFooter) then begin
    if Assigned(ListView.FOnInitFooter) then
      ListView.FOnInitFooter(ListView, FFooter);
    if not Assigned(FFooter) then
      FFooter := TListViewDefaultFooter.Create(Self);
    (FFooter as TControl).Parent := Self;
    (FFooter as TControl).Stored := False;
    if FIsDesigning then begin
      (FFooter as TControl).Align := TAlignLayout.Bottom;
      FFooter.DoUpdateState(TListViewState.None, 0);
    end else
      (FFooter as TControl).Visible := False;
  end;
end;

procedure TListViewContent.InitHeader;
begin
  if not Assigned(FHeader) then begin
    if Assigned(ListView.FOnInitHeader) then
      ListView.FOnInitHeader(ListView, FHeader);
    if not Assigned(FHeader) then
      FHeader := TListViewDefaultHeader.Create(Self);
    (FHeader as TControl).Parent := Self;
    (FHeader as TControl).Stored := False;
    (FHeader as TControl).Index := 0;
    if FIsDesigning then begin
      FHeader.DoUpdateState(TListViewState.None, 0);
      (FHeader as TControl).Align := TAlignLayout.Top;
    end else
      (FHeader as TControl).Visible := False;
  end;
end;

procedure TListViewContent.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Single);
begin
  FDownPos := PointF(X, Y);
  inherited;
end;

function TListViewContent.ObjectAtPoint(AScreenPoint: TPointF): IControl;
begin
  if Assigned(ListView.FAniCalculations) and (ListView.FAniCalculations.Shown) then
    Result := nil   // ���ƹ����У�������������
  else
    Result := inherited ObjectAtPoint(AScreenPoint);
end;

procedure TListViewContent.PaintBackground;
begin
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  if (FInVisible) or (Assigned(ListView) and (ListView.FInVisible)) then
    Exit;
  inherited PaintBackground;
  // ���ָ���
  if (FCount > 0) and (FirstRowIndex < FLastRowIndex) and (FViewBottom >= FLastPosition) then
    DrawDivider(Canvas);
end;

procedure TListViewContent.RemoveFooterView;
begin
  if Assigned(FFooterView) then begin
    RemoveObject(FFooterView);
    FFooterView := nil;
  end;
end;

procedure TListViewContent.RemoveHeaderView;
begin
  if Assigned(FHeaderView) then begin
    RemoveObject(FHeaderView);
    FHeaderView := nil;
  end;
end;

{ TListAdapterBase }

procedure TListAdapterBase.Clear;
begin
end;

constructor TListAdapterBase.Create;
begin
  DoInitData;
end;

procedure TListAdapterBase.DoInitData;
begin
end;

function TListAdapterBase.GetItemID(const Index: Integer): Int64;
begin
  Result := Index;
end;

function TListAdapterBase.GetItemViewType(const Index: Integer): Integer;
begin
  Result := ListViewType_Default;
end;

function TListAdapterBase.IsEmpty: Boolean;
begin
  Result := Count = 0;
end;

function TListAdapterBase.IsEnabled(const Index: Integer): Boolean;
begin
  Result := True;
end;

function TListAdapterBase.ItemDefaultHeight: Single;
begin
  Result := 50;
end;

procedure TListAdapterBase.ItemMeasureHeight(const Index: Integer; var AHeight: Single);
begin
end;

procedure TListAdapterBase.NotifyDataChanged;
begin
  if Assigned(FListView) then
    FListView.NotifyDataChanged;
end;

procedure TListAdapterBase.Repaint;
begin
  if Assigned(FListView) and Assigned(FListView.FContentViews) then
    FListView.FContentViews.Realign;
end;

{ TListAdapter<T> }

procedure TListAdapter<T>.Add(const Value: T);
begin
  Items.Add(Value);
end;

procedure TListAdapter<T>.Clear;
begin
  if Assigned(FList) then
    FList.Clear;
end;

constructor TListAdapter<T>.Create(const AItems: TList<T>);
begin
  SetItems(AItems);
  DoInitData;
end;

procedure TListAdapter<T>.Delete(const Index: Integer);
begin
  Items.Delete(Index);
end;

destructor TListAdapter<T>.Destroy;
begin
  if FListNeedFree then
    FreeAndNil(FList)
  else
    FList := nil;
  inherited;
end;

function TListAdapter<T>.GetCount: Integer;
begin
  if Assigned(FList) then
    Result := FList.Count
  else
    Result := 0;
end;

function TListAdapter<T>.GetItems: TList<T>;
begin
  if FList = nil then begin
    FList := TList<T>.Create;
    FListNeedFree := True;
  end;
  Result := FList;
end;

procedure TListAdapter<T>.Insert(const Index: Integer; const Value: T);
begin
  Items.Insert(Index, Value);
end;

function TListAdapter<T>.Remove(const Value: T): Integer;
begin
  Result := Items.Remove(Value);
end;

procedure TListAdapter<T>.SetItems(const Value: TList<T>);
begin
  if Assigned(FList) then begin
    if FListNeedFree then
      FreeAndNil(FList);
    FListNeedFree := False;
  end;
  FList := Value;
end;

{ TStringsListAdapter }

procedure TStringsListAdapter.Add(const V: string);
begin
  if FFlags = 0 then
    GetList.Add(V)
  else
    FArray.Append(V);
end;

procedure TStringsListAdapter.Add(const V: TArray<string>);
var
  I: Integer;
begin
  if FFlags = 0 then begin
    for I := 0 to High(V) do
      GetList.Add(V[I])
  end else
    FArray.Append(V);
end;

procedure TStringsListAdapter.Clear;
begin
  inherited Clear;
  if Assigned(FList) then
    FList.Clear;
  FArray.Clear;
end;

constructor TStringsListAdapter.Create(const AItems: TArray<string>);
begin
  SetArray(AItems);
  DoInitData;
end;

constructor TStringsListAdapter.Create(const AItems: TStrings);
begin
  if AItems <> nil then
    SetList(AItems);
  DoInitData;
end;

procedure TStringsListAdapter.Delete(const Index: Integer);
begin
  if FFlags = 0 then
    GetList.Delete(Index)
  else
    FArray.Delete(Index);
end;

destructor TStringsListAdapter.Destroy;
begin
  if FListNeedFree then
    FreeAndNil(FList)
  else
    FList := nil;
  inherited Destroy;
end;

function TStringsListAdapter.GetArray: TArray<string>;
begin
  Result := FArray;
end;

function TStringsListAdapter.GetCount: Integer;
begin
  if FFlags = 0 then begin
    if Assigned(FList) then
      Result := FList.Count
    else
      Result := 0;
  end else
    Result := FArray.Len;
end;

function TStringsListAdapter.GetItem(const Index: Integer): Pointer;
begin
  if FFlags = 0 then
    Result := PChar(FList[Index])
  else
    Result := PChar(FArray[Index]);
end;

function TStringsListAdapter.GetItemValue(const Index: Integer): string;
begin
  if FFlags = 0 then
    Result := FList[Index]
  else
    Result := FArray[Index];
end;

function TStringsListAdapter.GetList: TStrings;
begin
  if FList = nil then begin
    FListNeedFree := True;
    FList := TStringList.Create;
  end;
  Result := FList;
end;

function TStringsListAdapter.GetView(const Index: Integer;
  ConvertView: TViewBase; Parent: TViewGroup): TViewBase;
var
  ViewItem: TListTextItem;
begin
  if (ConvertView = nil) or (not (ConvertView is TListTextItem)) then begin
    ViewItem := TListTextItem.Create(Parent);
    ViewItem.Parent := Parent;
    ViewItem.Width := Parent.Width;
    ViewItem.MinHeight := TListTextItem.C_MinHeight;
    ViewItem.TextSettings.Font.Size := TListTextItem.C_FontSize;
    ViewItem.TextSettings.WordWrap := True;
    ViewItem.Gravity := TLayoutGravity.CenterVertical;
    ViewItem.Padding.Rect := RectF(8, 8, 8, 8);
    ViewItem.CanFocus := False;
  end else
    ViewItem := ConvertView as TListTextItem;
  ViewItem.HeightSize := TViewSize.WrapContent;
  ViewItem.Text := Items[Index];
  Result := ViewItem;
end;

function TStringsListAdapter.IndexOf(const AItem: Pointer): Integer;
begin
  Result := -1;
end;

procedure TStringsListAdapter.Insert(const Index: Integer; const V: string);
begin
  if FFlags = 0 then
    GetList.Insert(Index, V)
  else
    FArray.Insert(Index, V)
end;

function TStringsListAdapter.ItemDefaultHeight: Single;
begin
  Result := TListTextItem.C_MinHeight;
end;

procedure TStringsListAdapter.SetArray(const Value: TArray<string>);
begin
  FArray := Value;
  FFlags := 1;
end;

procedure TStringsListAdapter.SetArrayLength(const ACount: Integer);
begin
  FArray.Len := ACount;
  FFlags := 1;
end;

procedure TStringsListAdapter.SetItemValue(const Index: Integer;
  const Value: string);
begin
  if FFlags = 0 then begin
    FList[Index] := Value
  end else
    FArray[Index] := Value;
end;

procedure TStringsListAdapter.SetList(const Value: TStrings);
begin
  if not Assigned(FList) then begin
    if FListNeedFree then
      FreeAndNil(FList);
    FListNeedFree := False;
  end;
  FList := Value;
  FFlags := 0;
end;

{ TStringsListCheckAdapter }

procedure TStringsListCheckAdapter.Delete(const Index: Integer);
begin
  inherited;
  FChecks.Delete(Index);
end;

procedure TStringsListCheckAdapter.DoCheckChange(Sender: TObject);
var
  V: Boolean;
begin
  V := not ItemCheck[TControl(Sender).Tag];
  ItemCheck[TControl(Sender).Tag] := V;
  if Sender is TListViewItemCheck then
    TListViewItemCheck(Sender).CheckBox1.IsChecked := V;
end;

function TStringsListCheckAdapter.GetChecks: TArray<Boolean>;
begin
  Result := FChecks;
end;

function TStringsListCheckAdapter.GetItemCheck(const Index: Integer): Boolean;
begin
  if Index < FChecks.Len then
    Result := FChecks[Index]
  else
    Result := False;
end;

function TStringsListCheckAdapter.GetView(const Index: Integer;
  ConvertView: TViewBase; Parent: TViewGroup): TViewBase;
var
  ViewItem: TListViewItemCheck;
begin
  if (ConvertView = nil) or (not (TControl(ConvertView) is TListViewItemCheck)) then begin
    ViewItem := TListViewItemCheck.Create(Parent);
    ViewItem.Parent := Parent;
    ViewItem.BeginUpdate;
    ViewItem.WidthSize := TViewSize.FillParent;
    ViewItem.MinHeight := TListTextItem.C_MinHeight;
    ViewItem.Gravity := TLayoutGravity.CenterVertical;
    ViewItem.Width := Parent.Width;

    ViewItem.TextView1 := TTextView.Create(ViewItem);
    ViewItem.TextView1.WidthSize := TViewSize.FillParent;
    ViewItem.TextView1.HeightSize := TViewSize.WrapContent;
    ViewItem.TextView1.TextSettings.Font.Size := TListTextItem.C_FontSize;
    ViewItem.TextView1.TextSettings.WordWrap := True;
    //ViewItem.TextView1.TextSettings.Trimming := TTextTrimming.Character;
    ViewItem.TextView1.Gravity := TLayoutGravity.CenterVertical;
    ViewItem.TextView1.Margins.Rect := RectF(0, 0, 4, 0);
    ViewItem.TextView1.Padding.Rect := RectF(8, 8, 8, 8);
    ViewItem.TextView1.AutoSize := True;
    ViewItem.TextView1.Parent := ViewItem;

    ViewItem.CheckBox1 := TCheckBox.Create(ViewItem);
    ViewItem.CheckBox1.Text := '';
    ViewItem.CheckBox1.Width := 42;
    ViewItem.CheckBox1.Height := ViewItem.MinHeight;
    ViewItem.CheckBox1.Parent := ViewItem;
    ViewItem.CheckBox1.HitTest := False;
    ViewItem.CanFocus := False;
    ViewItem.EndUpdate;
  end else
    ViewItem := TControl(ConvertView) as TListViewItemCheck;

  ViewItem.BeginUpdate;
  ViewItem.Tag := Index;   // ʹ�� Tag ��¼������
  ViewItem.OnClick := DoCheckChange;
  ViewItem.CheckBox1.IsChecked := ItemCheck[Index];
  ViewItem.HeightSize := TViewSize.WrapContent;
  ViewItem.DoRealign;
  ViewItem.TextView1.Text := Items[Index];
  ViewItem.Height := ViewItem.TextView1.Size.Height;
  ViewItem.EndUpdate;
  Result := TViewBase(ViewItem);
end;

procedure TStringsListCheckAdapter.Insert(const Index: Integer;
  const V: string);
begin
  inherited;
  if FChecks.Len >= Index + 1 then
    FChecks.Insert(Index, False);
end;

procedure TStringsListCheckAdapter.SetChecks(const Value: TArray<Boolean>);
begin
  FChecks := Value;
  Repaint;
end;

procedure TStringsListCheckAdapter.SetItemCheck(const Index: Integer;
  const Value: Boolean);
begin
  if FChecks.Len < Count then
    FChecks.Len := Count;
  FChecks[Index] := Value;
end;

{ TStringsListSingleAdapter }

procedure TStringsListSingleAdapter.DoInitData;
begin
  inherited DoInitData;
  FItemIndex := -1;
end;

procedure TStringsListSingleAdapter.DoItemIndexChange(Sender: TObject);
begin
  FItemIndex := TControl(Sender).Tag;
  if Sender is TListViewItemSingle then
    TListViewItemSingle(Sender).RadioButton.IsChecked := True;
end;

function TStringsListSingleAdapter.GetView(const Index: Integer;
  ConvertView: TViewBase; Parent: TViewGroup): TViewBase;
var
  ViewItem: TListViewItemSingle;
begin
  if (ConvertView = nil) or (not (TControl(ConvertView) is TListViewItemSingle)) then begin
    ViewItem := TListViewItemSingle.Create(Parent);
    ViewItem.Parent := Parent;
    ViewItem.BeginUpdate;
    ViewItem.WidthSize := TViewSize.FillParent;
    ViewItem.MinHeight := TListTextItem.C_MinHeight;
    ViewItem.Gravity := TLayoutGravity.CenterVertical;
    ViewItem.Width := Parent.Width;

    ViewItem.TextView1 := TTextView.Create(ViewItem);
    ViewItem.TextView1.WidthSize := TViewSize.FillParent;
    ViewItem.TextView1.HeightSize := TViewSize.WrapContent;
    ViewItem.TextView1.TextSettings.Font.Size := TListTextItem.C_FontSize;
    ViewItem.TextView1.TextSettings.WordWrap := True;
    ViewItem.TextView1.Gravity := TLayoutGravity.CenterVertical;
    ViewItem.TextView1.Margins.Rect := RectF(0, 0, 4, 0);
    ViewItem.TextView1.Padding.Rect := RectF(8, 8, 8, 8);
    ViewItem.TextView1.AutoSize := True;
    ViewItem.TextView1.Parent := ViewItem;

    ViewItem.RadioButton := TRadioButton.Create(ViewItem);
    ViewItem.RadioButton.Width := 42;
    ViewItem.RadioButton.Height := ViewItem.MinHeight;
    ViewItem.RadioButton.Parent := ViewItem;
    ViewItem.RadioButton.Text := '';
    ViewItem.RadioButton.HitTest := False;
    ViewItem.TextView1.Width := ViewItem.Width - ViewItem.RadioButton.Width - 4;
    ViewItem.CanFocus := False;
    ViewItem.EndUpdate;
  end else
    ViewItem := TControl(ConvertView) as TListViewItemSingle;

  ViewItem.Tag := Index; // ʹ�� Tag ��¼������
  ViewItem.OnClick := DoItemIndexChange;
  ViewItem.BeginUpdate;
  ViewItem.RadioButton.IsChecked := FItemIndex = Index;
  ViewItem.HeightSize := TViewSize.WrapContent;
  ViewItem.DoRealign;
  ViewItem.TextView1.Text := Items[Index];
  ViewItem.Height := ViewItem.TextView1.Height;
  ViewItem.EndUpdate;
  Result := TViewBase(ViewItem);
end;

procedure TStringsListSingleAdapter.SetItemIndex(const Value: Integer);
begin
  FItemIndex := Value;
end;

{ TTreeListNode<T> }

procedure TTreeListNode<T>.Add(const ANode: TTreeListNode<T>);
begin
  if not Assigned(ANode) then
    Exit;
  if not Assigned(FNodes) then CreateNodes;
  if FNodes.IndexOf(ANode) < 0 then begin
    ANode.Parent := Self;
    FNodes.Add(ANode);
  end;
end;

function TTreeListNode<T>.AddNode(const AData: T): TTreeListNode<T>;
begin
  if not Assigned(FNodes) then CreateNodes;
  Result := TTreeListNode<T>.Create;
  Result.FData := AData;
  Result.FParent := Self;
  Result.UpdateLevel;
  FNodes.Add(Result);
end;

procedure TTreeListNode<T>.Clear;
begin
  if Assigned(FNodes) then
    FNodes.Clear;
end;

constructor TTreeListNode<T>.Create;
begin
  FNodes := nil;
  FExpanded := False;
end;

procedure TTreeListNode<T>.CreateNodes;
begin
  if not Assigned(FNodes) then begin
    FNodes := TList<TTreeListNode<T>>.Create;
    FNodes.OnNotify := DoNodeNotify;
  end;
end;

destructor TTreeListNode<T>.Destroy;
begin
  if Assigned(FNodes) then
    Parent := nil;
  FreeAndNil(FNodes);
  inherited;
end;

procedure TTreeListNode<T>.DoNodeNotify(Sender: TObject;
  const Item: TTreeListNode<T>; Action: System.Generics.Collections.TCollectionNotification);
begin
  if Action = System.Generics.Collections.TCollectionNotification.cnRemoved then
    if Assigned(Item) then Item.DisposeOf;
end;

function TTreeListNode<T>.GetCount: Integer;
begin
  if Assigned(FNodes) then
    Result := FNodes.Count
  else
    Result := 0;
end;

function TTreeListNode<T>.GetNode(const Index: Integer): TTreeListNode<T>;
begin
  if Assigned(FNodes) and (Index >= 0) and (Index < FNodes.Count) then
    Result := FNodes.Items[Index]
  else
    Result := nil;
end;

function TTreeListNode<T>.GetParentIndex: Integer;
begin
  if Assigned(FParent) then
    Result := FParent.FNodes.IndexOf(Self)
  else
    Result := -1;
end;

procedure TTreeListNode<T>.Insert(const Index: Integer;
  const ANode: TTreeListNode<T>);
begin
  if not Assigned(ANode) then Exit;
  if not Assigned(FNodes) then CreateNodes;
  ANode.Parent := Self;
  if (Index < 0) or (Index >= FNodes.Count) then
    FNodes.Add(ANode)
  else
    FNodes.Insert(Index, ANode);
end;

function TTreeListNode<T>.InsertNode(const Index: Integer; const AData: T): TTreeListNode<T>;
begin
  if not Assigned(FNodes) then CreateNodes;
  Result := TTreeListNode<T>.Create;
  Result.FData := AData;
  Result.FParent := Self;
  if (Index < 0) or (Index >= FNodes.Count) then
    FNodes.Add(Result)
  else begin
    FNodes.Insert(Index, Result);
  end;
  Result.UpdateLevel;
end;

procedure TTreeListNode<T>.Remove(const ANode: TTreeListNode<T>);
begin
  if not Assigned(FNodes) then Exit;
  FNodes.Remove(ANode);
end;

procedure TTreeListNode<T>.InnerRemove(const ANode: TTreeListNode<T>);
begin
  if not Assigned(FNodes) then Exit;
  FNodes.OnNotify := nil;
  FNodes.Remove(ANode);
  FNodes.OnNotify := DoNodeNotify;
end;

procedure TTreeListNode<T>.SetNode(const Index: Integer;
  const Value: TTreeListNode<T>);
begin
  if not Assigned(FNodes) then Exit;
  if (Index < 0) or (Index >= FNodes.Count) then Exit;
  FNodes.Items[Index] := Value;
end;

procedure TTreeListNode<T>.SetParent(const Value: TTreeListNode<T>);
begin
  if FParent <> Value then begin
    if Assigned(FParent) then
      FParent.InnerRemove(Self);
    FParent := Value;
    if Assigned(FParent) then begin
      FParent.Add(Self);
      UpdateLevel;
    end else
      FLevel := -1;
  end;
end;

procedure TTreeListNode<T>.UpdateLevel;
var
  I: Integer;
  P: TTreeListNode<T>;
begin
  I := -1;
  P := FParent;
  while P <> nil do begin
    Inc(I);
    P := P.FParent;
  end;
  FLevel := I;
end;

{ TCustomTreeListDataAdapter<T> }

procedure TCustomTreeListDataAdapter<T>.AddListItem(
  const Parent: TTreeListNode<T>);
var
  I: Integer;
begin
  for I := 0 to Parent.Count - 1 do begin
    FList.Add(Parent.Nodes[I]);
    if Parent.Nodes[I].Expanded then
      AddListItem(Parent.Nodes[I]);
  end;
end;

procedure TCustomTreeListDataAdapter<T>.BeginUpdate;
begin
  Inc(FUpdateRef);
end;

procedure TCustomTreeListDataAdapter<T>.Clear;
begin
  inherited Clear;
  if Assigned(FRoot) then
    FRoot.Clear;
  if Assigned(FList) then
    FList.Clear;
end;

constructor TCustomTreeListDataAdapter<T>.Create();
begin
  FRoot := TTreeListNode<T>.Create;
  FList := TList<TTreeListNode<T>>.Create;
end;

destructor TCustomTreeListDataAdapter<T>.Destroy;
begin
  FreeAndNil(FList);
  FreeAndNil(FRoot);
  inherited;
end;

procedure TCustomTreeListDataAdapter<T>.DoNodeExpandChange(Sender: TObject);
var
  B: Boolean;
begin
  B := not FList.Items[TControl(Sender).Tag].Expanded;
  FList.Items[TControl(Sender).Tag].Expanded := B;
  ListView.FContentViews.HideViews;
  NotifyDataChanged;
end;

procedure TCustomTreeListDataAdapter<T>.EndUpdate;
begin
  Dec(FUpdateRef);
  if FUpdateRef < 0 then
    FUpdateRef := 0;
  if FUpdateRef = 0 then
    InitList;
end;

function TCustomTreeListDataAdapter<T>.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TCustomTreeListDataAdapter<T>.GetItem(const Index: Integer): Pointer;
begin
  Result := FList.Items[Index];
end;

function TCustomTreeListDataAdapter<T>.GetItemViewType(
  const Index: Integer): Integer;
begin
  Result := FList.Items[Index].Level;
end;

function TCustomTreeListDataAdapter<T>.GetNodeCount: Integer;
begin
  Result := FRoot.Count;
end;

function TCustomTreeListDataAdapter<T>.GetNodeGroupView(const Index: Integer;
  const ANode: TTreeListNode<T>; ConvertView: TViewBase;
  Parent: TViewGroup): TViewBase;
var
  ViewItem: TListViewTreeGroup;
begin
  if (ConvertView = nil) or (not (TControl(ConvertView) is TListViewTreeGroup)) then begin
    ViewItem := TListViewTreeGroup.Create(Parent);
    ViewItem.Parent := Parent;
    ViewItem.Width := Parent.Width;
    ViewItem.Height := TListTextItem.C_MinHeight;
    ViewItem.HitTest := False;
    ViewItem.CanFocus := False;
  end else
    ViewItem := TControl(ConvertView) as TListViewTreeGroup;
  ViewItem.BeginUpdate;
  ViewItem.TextView.Tag := Index;  // ʹ�� Tag ��¼������
  ViewItem.TextView.OnClick := DoNodeExpandChange;
  ViewItem.TextView.Text := GetNodeText(ANode);
  ViewItem.TextView.Checked := ANode.Expanded;
  ViewItem.EndUpdate;
  Result := TViewBase(ViewItem);
end;

function TCustomTreeListDataAdapter<T>.GetNodeItemView(const Index: Integer;
  const ANode: TTreeListNode<T>; ConvertView: TViewBase;
  Parent: TViewGroup): TViewBase;
var
  ViewItem: TListTextItem;
begin
  if (ConvertView = nil) or (not (ConvertView is TListTextItem)) then begin
    ViewItem := TListTextItem.Create(Parent);
    ViewItem.Parent := Parent;
    ViewItem.Width := Parent.Width;
    ViewItem.Height := TListTextItem.C_MinHeight;
    ViewItem.HeightSize := TViewSize.CustomSize;
    ViewItem.MinHeight := TListTextItem.C_MinHeight;
    ViewItem.TextSettings.Font.Size := TListTextItem.C_FontSize;
    ViewItem.TextSettings.WordWrap := True;
    ViewItem.Gravity := TLayoutGravity.CenterVertical;
    ViewItem.Padding.Rect := RectF(8, 8, 8, 8);
    ViewItem.CanFocus := False;
  end else
    ViewItem := ConvertView as TListTextItem;
  ViewItem.Text := GetNodeText(ANode);
  Result := ViewItem;
end;

function TCustomTreeListDataAdapter<T>.GetNodes(
  const Index: Integer): TTreeListNode<T>;
begin
  Result := FList.Items[Index];
end;

function TCustomTreeListDataAdapter<T>.GetNodeText(
  const ANode: TTreeListNode<T>): string;
begin
  Result := ANode.ToString();
end;

function TCustomTreeListDataAdapter<T>.GetView(const Index: Integer;
  ConvertView: TViewBase; Parent: TViewGroup): TViewBase;
var
  ViewItem: TListTextItem;
  Node: TTreeListNode<T>;
begin
  Node := Nodes[Index];
  if (Node.Level = 0) or (Node.Count > 1) then
    Result := GetNodeGroupView(Index, Node, ConvertView, Parent)
  else
    Result := GetNodeItemView(Index, Node, ConvertView, Parent)
end;

function TCustomTreeListDataAdapter<T>.IndexOf(const AItem: Pointer): Integer;
begin
  Result := FList.IndexOf(AItem);
end;

procedure TCustomTreeListDataAdapter<T>.InitList;
begin
  FList.Clear;
  AddListItem(FRoot);
end;

procedure TCustomTreeListDataAdapter<T>.ItemMeasureHeight(const Index: Integer; var AHeight: Single);
begin
  if FList.Items[Index].Level = 0 then
    AHeight := 36
end;

procedure TCustomTreeListDataAdapter<T>.NotifyDataChanged;
begin
  InitList;
  inherited NotifyDataChanged;
  if Assigned(ListView) then
    ListView.Invalidate;
end;

{ TStringsListIconAdapter }

procedure TStringsListIconAdapter.DoInitData;
begin
  inherited;
  FIconSize.Width := 16;
  FIconSize.Height := 16;
  FPadding := 8;
end;

function TStringsListIconAdapter.GetItemImageIndex(
  const Index: Integer): Integer;
begin
  Result := Index;
end;

function TStringsListIconAdapter.GetView(const Index: Integer;
  ConvertView: TViewBase; Parent: TViewGroup): TViewBase;
var
  ViewItem: TListTextItem;
begin
  if (ConvertView = nil) or (not (ConvertView is TListTextItem)) then begin
    ViewItem := TListTextItem.Create(Parent);
    ViewItem.Parent := Parent;
    ViewItem.Width := Parent.Width;
    ViewItem.MinHeight := TListTextItem.C_MinHeight;
    ViewItem.TextSettings.Font.Size := TListTextItem.C_FontSize;
    ViewItem.TextSettings.WordWrap := True;
    ViewItem.Gravity := TLayoutGravity.CenterVertical;
    ViewItem.Padding.Rect := RectF(8, 8, 8, 8);
    if Assigned(FImages) then begin
      ViewItem.Drawable.Images := FImages;
      ViewItem.Drawable.Position := FPosition;
      ViewItem.Drawable.SizeWidth := FIconSize.Width;
      ViewItem.Drawable.SizeHeight := FIconSize.Height;
      ViewItem.Drawable.Padding := FPadding;
    end;
    ViewItem.CanFocus := False;
  end else
    ViewItem := ConvertView as TListTextItem;
  if Assigned(FImages) then
  ViewItem.HeightSize := TViewSize.WrapContent;
  ViewItem.Text := Items[Index];
  if Assigned(FImages) then
    TViewImagesBrush(ViewItem.Drawable.ItemDefault).ImageIndex := GetItemImageIndex(Index);
  Result := ViewItem;
end;

end.
