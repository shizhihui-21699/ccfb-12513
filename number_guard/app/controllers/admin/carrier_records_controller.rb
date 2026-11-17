module Admin
  # 模拟运营商数据维护（真实场景由运营商接口提供，这里本地维护用于演示）
  class CarrierRecordsController < BaseController
    def index
      @records = CarrierRecord.order(activated_at: :desc).limit(200)
    end

    def new
      @record = CarrierRecord.new
    end

    def create
      @record = CarrierRecord.new(record_params)
      if @record.save
        redirect_to admin_carrier_records_path, notice: "已录入号码 #{@record.phone} 的运营商数据"
      else
        render :new
      end
    end

    def edit
      @record = CarrierRecord.find(params[:id])
    end

    def update
      @record = CarrierRecord.find(params[:id])
      if @record.update(record_params)
        redirect_to admin_carrier_records_path, notice: "已更新号码 #{@record.phone} 的运营商数据"
      else
        render :edit
      end
    end

    def destroy
      CarrierRecord.find(params[:id]).destroy
      redirect_to admin_carrier_records_path, notice: "已删除"
    end

    private

    def record_params
      params.require(:carrier_record).permit(:phone, :carrier_name, :activated_at, :status)
    end
  end
end
