// models/user.js
const { DataTypes } = require("sequelize");
const sequelize = require("../config/db"); // Adjust path as necessary
const { v4: uuidv4 } = require("uuid");

const User = sequelize.define(
  "User",
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      allowNull: false,
      primaryKey: true,
    },
    email: {
      type: DataTypes.STRING,
      unique: true,
      allowNull: false,
    },
    password: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    first_name: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    last_name: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    account_created: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
    },
    profile_image: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    upload_date: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    account_updated: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
    },
    verified: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
      validate: {
        notNull: true,
        notEmpty: true,
      },
    },
    verified_on: {
      type: DataTypes.BOOLEAN,
      allowNull: true,
    },
  },
  {
    tableName: "Users",
    hooks: {
      beforeCreate: async (user) => {
        const bcrypt = require("bcryptjs");
        const salt = await bcrypt.genSalt(10);
        user.password = await bcrypt.hash(user.password, salt);
      },
      beforeUpdate: async (user) => {
        user.account_updated = new Date();
      },
    },
    timestamps: false,
  },
);

module.exports = User;
