{*******************************************************}
{                                                       }
{       FMX UI ���������Ԫ                             }
{                                                       }
{       ��Ȩ���� (C) 2017 YangYxd                       }
{                                                       }
{*******************************************************}

unit UI.Calendar;

interface

uses
  UI.Base, UI.Utils, UI.Ani, UI.Calendar.Data,
  FMX.Effects, FMX.Text,
  {$IFDEF MSWINDOWS}UI.Debug, {$ENDIF}
  FMX.Objects, System.Math, System.Actions, System.DateUtils, FMX.Consts,
  System.TypInfo, FMX.Graphics, System.Generics.Collections, FMX.TextLayout,
  System.Classes, System.Types, System.UITypes, System.SysUtils, System.Math.Vectors,
  FMX.Types, FMX.StdCtrls, FMX.Platform, FMX.Controls, FMX.InertialMovement,
  FMX.Ani, FMX.StdActns;

type
  /// <summary>
  /// ����ѡ��
  /// </summary>
  TCalendarOption = (
     coShowNavigation, {��ʾ����}
     coShowWeek, {��ʾ����}
     coCalendarWeeks, {��ʾ����}
     coTodayHighlight, {��������}
     coShowTodayButton, {��ʾ���찴ť}
     coShowLunar, {��ʾũ��}
     coShowTerm {��ʾ��������Ҫ���� coShowLunar}
  );
  TCalendarOptions = set of TCalendarOption;

  TCalendarWeekItem = (
    Week0, Week1, Week2, Week3, Week4, Week5, Week6
  );
  TCalendarWeeks = set of TCalendarWeekItem;

type
  /// <summary>
  /// ������ͼ����
  /// </summary>
  TCalendarViewType = (Days {��}, Months {��}, Years {��}, Decades {10��});
  /// <summary>
  /// ���ڿ�ʼֵ
  /// </summary>
  TWeekStart = Integer;

const
  CDefaultCalendarOptions = [coShowWeek, coShowNavigation, coTodayHighlight];

type
  /// <summary>
  /// �������Խӿ�
  /// </summary>
  ICalendarLanguage = interface
    ['{16B861E6-87E7-4C50-9808-33D1C0CF249B}']
    function WeekStrList: TArray<string>;
    function MonthsStrList: TArray<string>;
    function DateToStr(const Value: TDate): string;
  end;

type
  /// <summary>
  /// �������� - ����
  /// </summary>
  TCalendarLanguage_CN = class(TComponent, ICalendarLanguage)
  public
    function WeekStrList: TArray<string>;
    function MonthsStrList: TArray<string>;
    function DateToStr(const Value: TDate): string;
  end;

  /// <summary>
  /// �������� - Ӣ��
  /// </summary>
  TCalendarLanguage_EN = class(TComponent, ICalendarLanguage)
  public
    function WeekStrList: TArray<string>;
    function MonthsStrList: TArray<string>;
    function DateToStr(const Value: TDate): string;
  end;

type
  TCalendarViewBase = class(TView)
  private
    [Weak] FLanguage: ICalendarLanguage;
    FOptions: TCalendarOptions;
    FStartView: TCalendarViewType;
    FStartDate: TDate;
    FEndDate: TDate;
    FWeekStart: TWeekStart;
    FDaysOfWeekDisabled: TCalendarWeeks;
    FDaysOfWeekHighlighted: TCalendarWeeks;

    procedure SetOptions(const Value: TCalendarOptions);
    procedure SetEndDate(const Value: TDate);
    procedure SetLanguage(const Value: ICalendarLanguage);
    procedure SetStartDate(const Value: TDate);
    procedure SetStartView(const Value: TCalendarViewType);
    procedure SetWeekStart(const Value: TWeekStart);
    function IsEndDateStored: Boolean;
    function IsStartDateStored: Boolean;
    function GetLanguage: ICalendarLanguage;
    procedure SetDaysOfWeekDisabled(const Value: TCalendarWeeks);
    procedure SetDaysOfWeekHighlighted(const Value: TCalendarWeeks);
  protected
    procedure DoOptionsChange; virtual;
    procedure DoChange; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    /// <summary>
    /// ѡ��
    /// </summary>
    property Options: TCalendarOptions read FOptions write SetOptions;
    /// <summary>
    /// ��ʼʱ��ʾ����ͼ����
    /// </summary>
    property StartView: TCalendarViewType read FStartView write SetStartView;
    /// <summary>
    /// �޶��Ŀ�ʼ����
    /// </summary>
    property StartDate: TDate read FStartDate write SetStartDate stored IsStartDateStored;
    /// <summary>
    /// �޶��Ľ�������
    /// </summary>
    property EndDate: TDate read FEndDate write SetEndDate stored IsEndDateStored;
    /// <summary>
    /// ������ʾ�����ڼ���ʼ��Ĭ��Ϊ0���������쿪ʼ
    /// </summary>
    property WeekStart: TWeekStart read FWeekStart write SetWeekStart;
    /// <summary>
    /// ���Խӿ�
    /// </summary>
    property Language: ICalendarLanguage read GetLanguage write SetLanguage;


    /// <summary>
    /// ��ֹѡ������������ڼ�
    /// </summary>
    property DaysOfWeekDisabled: TCalendarWeeks read FDaysOfWeekDisabled write SetDaysOfWeekDisabled;
    /// <summary>
    /// ������ʾ�����������ڼ�
    /// </summary>
    property DaysOfWeekHighlighted: TCalendarWeeks read FDaysOfWeekHighlighted write SetDaysOfWeekHighlighted;
  end;

type
  /// <summary>
  /// ������ͼ���
  /// </summary>
  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TCalendarView = class(TCalendarViewBase)
  published
    property Options default CDefaultCalendarOptions;
    property StartView default TCalendarViewType.Days;
    property StartDate;
    property EndDate;
    property WeekStart default 0;
    property Language;
    property DaysOfWeekDisabled;
    property DaysOfWeekHighlighted;
  end;

implementation

var
  DefaultLanguage: TCalendarLanguage_EN;

{ TCalendarLanguage_CN }

function TCalendarLanguage_CN.DateToStr(const Value: TDate): string;
begin
  Result := FormatDateTime('yyyy��mm��', Value);
end;

function TCalendarLanguage_CN.MonthsStrList: TArray<string>;
begin
  Result := ['1��', '2��', '3��', '4��', '5��', '6��',
    '7��', '8��', '9��', '10��', '11��', '12��'];
end;

function TCalendarLanguage_CN.WeekStrList: TArray<string>;
begin
  Result := ['��', 'һ', '��', '��', '��', '��', '��'];
end;

{ TCalendarLanguage_EN }

function TCalendarLanguage_EN.DateToStr(const Value: TDate): string;
const
  LMonths: array [0..11] of string = (
    'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December');
var
  Y, M, D: Word;
begin
  DecodeDate(Value, Y, M, D);
  Result := Format('%s %d', [LMonths[M], Y]);
end;

function TCalendarLanguage_EN.MonthsStrList: TArray<string>;
begin
  Result := ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
end;

function TCalendarLanguage_EN.WeekStrList: TArray<string>;
begin
  Result := ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
end;

{ TCalendarViewBase }

constructor TCalendarViewBase.Create(AOwner: TComponent);
begin
  inherited;
  if not (csDesigning in ComponentState) then  
    FLanguage := DefaultLanguage;
  FOptions := CDefaultCalendarOptions;
end;

destructor TCalendarViewBase.Destroy;
begin
  inherited;
end;

procedure TCalendarViewBase.DoChange;
begin
  Invalidate;
end;

procedure TCalendarViewBase.DoOptionsChange;
begin
  Invalidate;
end;

function TCalendarViewBase.GetLanguage: ICalendarLanguage;
begin
  if (not Assigned(FLanguage)) and (not (csDesigning in ComponentState)) then
    FLanguage := DefaultLanguage;
  Result := FLanguage;
end;

function TCalendarViewBase.IsEndDateStored: Boolean;
begin
  Result := FEndDate <> 0;
end;

function TCalendarViewBase.IsStartDateStored: Boolean;
begin
  Result := FStartDate <> 0;
end;

procedure TCalendarViewBase.SetDaysOfWeekDisabled(const Value: TCalendarWeeks);
begin
  if FDaysOfWeekDisabled <> Value then begin
    FDaysOfWeekDisabled := Value;
    DoChange;
  end;
end;

procedure TCalendarViewBase.SetDaysOfWeekHighlighted(
  const Value: TCalendarWeeks);
begin
  if FDaysOfWeekHighlighted <> Value then begin
    FDaysOfWeekHighlighted := Value;
    DoChange;
  end;
end;

procedure TCalendarViewBase.SetEndDate(const Value: TDate);
begin
  if FEndDate <> Value then begin
    FEndDate := Value;
    DoChange();
  end;
end;

procedure TCalendarViewBase.SetLanguage(const Value: ICalendarLanguage);
begin
  if FLanguage <> Value then begin
    FLanguage := Value;
    if (not Assigned(FLanguage)) and (not (csDesigning in ComponentState)) then
      FLanguage := DefaultLanguage;
    DoChange;
  end;
end;

procedure TCalendarViewBase.SetOptions(const Value: TCalendarOptions);
begin
  if FOptions <> Value then begin
    FOptions := Value;
    DoOptionsChange();
  end;
end;

procedure TCalendarViewBase.SetStartDate(const Value: TDate);
begin
  if FStartDate <> Value then begin
    FStartDate := Value;
    DoChange;
  end;
end;

procedure TCalendarViewBase.SetStartView(const Value: TCalendarViewType);
begin
  if FStartView <> Value then begin
    FStartView := Value;
    DoChange;
  end;
end;

procedure TCalendarViewBase.SetWeekStart(const Value: TWeekStart);
begin
  if FWeekStart <> Value then begin
    FWeekStart := Value;
    DoChange;
  end;
end;

initialization
  DefaultLanguage := TCalendarLanguage_EN.Create(nil);

finalization
  FreeAndNil(DefaultLanguage);

end.
