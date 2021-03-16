class CustomersController < ApplicationController
  require 'customer_datatable'

  def index
    rescue_wrapper {
      respond_to do |format|
        format.html
        format.json do
          render json: CustomersDatatable.new(view_context, []) 
        end
      end
    }
  end

  def show
    rescue_wrapper {
      @customer = Customer.find(params[:id])
    }
  end

  def new
    rescue_wrapper {  
      @customer = Customer.new
    }
  end

  def create
    rescue_wrapper {
      customer = Customer.create(customer_params)
      redirect_to customer_path(customer)
    }
  end
  
  def edit
    rescue_wrapper {
      @customer = Customer.find(params[:id])
    }
  end

  def update
    rescue_wrapper {  
      @customer = Customer.find(params[:id])
      data = @customer.update(customer_params)

      if data[:status] == "SUCCESS"
        redirect_to customer_path(@customer)
      else
        @customer = data[:model_object]
        render :edit
      end
    }
  end

  private

  def customer_params
    params.require(:customer).permit(
      :customer_type, :username, :date_of_birth, :gender, :phone_number
    )
  end
end
