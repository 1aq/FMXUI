unit UI.WaitDialog;

interface

uses
  UI.Base, UI.Toast, UI.Dialog,
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Forms;

/// <summary>
/// �ȴ��Ի����Ƿ�ȡ����
/// </summary>
function IsWaitDismiss: Boolean;

/// <summary>
/// ���صȴ��Ի���
/// </summary>
procedure HideWaitDialog;

/// <summary>
/// ��ʾ�ȴ��Ի���
/// </summary>
procedure ShowWaitDialog(const AMsg: string; ACancelable: Boolean = True); overload;
/// <summary>
/// ��ʾ�ȴ��Ի���
/// </summary>
procedure ShowWaitDialog(const AMsg: string;
  OnDismissListener: TOnDialogListener; ACancelable: Boolean = True); overload;
/// <summary>
/// ��ʾ�ȴ��Ի���
/// </summary>
procedure ShowWaitDialog(const AMsg: string;
  OnDismissListener: TOnDialogListenerA; ACancelable: Boolean = True); overload;

/// <summary>
/// ���µȴ��Ի�����Ϣ����
/// </summary>
procedure UpdateWaitDialog(const AMsg: string);

/// <summary>
/// �Ǳ��룬��ʼ���ȴ��Ի���
/// </summary>
/// <remarks>
/// ������ ShowWaitDialog ֮ǰ���ã����һ�ر�����ʾ�ĵȴ��Ի���
/// </remarks>
procedure InitWaitDialog(const AParent: TFmxObject);

implementation

var
  FWaitDialog: TProgressDialog = nil;

function IsWaitDismiss: Boolean;
begin
  Result := (not Assigned(FWaitDialog)) or (FWaitDialog.IsDismiss)
end;

procedure HideWaitDialog;
begin
  if not IsWaitDismiss then begin
    FWaitDialog.Dismiss;
    FWaitDialog := nil;
  end;
end;

procedure ShowWaitDialog(const AMsg: string;
  OnDismissListener: TOnDialogListener; ACancelable: Boolean);
begin
  ShowWaitDialog(AMsg, ACancelable);
  if Assigned(FWaitDialog) then
    FWaitDialog.OnDismissListener := OnDismissListener;
end;

procedure ShowWaitDialog(const AMsg: string;
  OnDismissListener: TOnDialogListenerA; ACancelable: Boolean);
begin
  ShowWaitDialog(AMsg, ACancelable);
  if Assigned(FWaitDialog) then
    FWaitDialog.OnDismissListenerA := OnDismissListener;
end;

procedure ShowWaitDialog(const AMsg: string; ACancelable: Boolean);
begin
  if IsWaitDismiss then begin
    FWaitDialog := nil;
    FWaitDialog := TProgressDialog.Create(Application.MainForm);
  end;
  FWaitDialog.Cancelable := ACancelable;
  if not Assigned(FWaitDialog.RootView) then
    FWaitDialog.InitView(AMsg)
  else
    FWaitDialog.Message := AMsg;
  TDialog(FWaitDialog).Show();
end;

procedure UpdateWaitDialog(const AMsg: string);
begin
  if IsWaitDismiss then
    Exit;
  if Assigned(FWaitDialog.RootView) then begin
    FWaitDialog.Message := AMsg;
    FWaitDialog.RootView.MessageView.Text := AMsg;
  end;
end;

procedure InitWaitDialog(const AParent: TFmxObject);
begin
  if not Assigned(AParent) then
    Exit;
  HideWaitDialog;
  FWaitDialog := TProgressDialog.Create(AParent);
end;

initialization

finalization
  FWaitDialog := nil;

end.
