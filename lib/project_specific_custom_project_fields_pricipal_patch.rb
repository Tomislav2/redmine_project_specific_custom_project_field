
class Principal < ActiveRecord::Base

  scope :like, lambda {|q|
    q = q.to_s
    if q.blank?
      where({})
    else
      pattern = "%#{q}%"
      sql = "LOWER(#{table_name}.login) LIKE LOWER(:p)"
      sql << " OR #{table_name}.id IN (SELECT user_id FROM #{EmailAddress.table_name} WHERE LOWER(address) LIKE LOWER(:p))"
      params = {:p => pattern}

      tokens = q.split(/\s+/).reject(&:blank?).map { |token| "%#{token}%" }
      if tokens.present?
        sql << ' OR ('
        sql << (tokens.map.with_index do |token, index|
          params.merge!(:"token_#{index}" => token)
          "(LOWER(#{table_name}.firstname) LIKE LOWER(:token_#{index}) OR LOWER(#{table_name}.lastname) LIKE LOWER(:token_#{index}))"
        end).join(' AND ')
        sql << ')'
      end

      where(sql, params)
    end
  }
end